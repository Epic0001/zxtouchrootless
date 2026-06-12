#import "TemplateMatch.h"
#import <Accelerate/Accelerate.h>
#import <UIKit/UIKit.h>
#include <math.h>

// Convert a CGImage to a grayscale float buffer (caller must free)
static float* cgImageToGrayscaleFloat(CGImageRef img, size_t *outWidth, size_t *outHeight) {
    size_t w = CGImageGetWidth(img);
    size_t h = CGImageGetHeight(img);
    *outWidth = w;
    *outHeight = h;

    size_t bytesPerRow = w * 4;
    unsigned char *rgba = (unsigned char *)malloc(bytesPerRow * h);
    if (!rgba) return NULL;

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(rgba, w, h, 8, bytesPerRow, cs,
                                             kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), img);
    CGContextRelease(ctx);

    float *gray = (float *)malloc(w * h * sizeof(float));
    if (!gray) { free(rgba); return NULL; }

    // Luminance: 0.299R + 0.587G + 0.114B
    for (size_t i = 0; i < w * h; i++) {
        gray[i] = 0.299f * rgba[i*4] + 0.587f * rgba[i*4+1] + 0.114f * rgba[i*4+2];
    }
    free(rgba);
    return gray;
}

// Load an image file to grayscale float buffer
static float* loadImageToGrayscaleFloat(NSString *path, size_t *outWidth, size_t *outHeight) {
    UIImage *ui = [UIImage imageWithContentsOfFile:path];
    if (!ui) return NULL;
    CGImageRef cg = ui.CGImage;
    if (!cg) return NULL;
    return cgImageToGrayscaleFloat(cg, outWidth, outHeight);
}

// Resize a float buffer using vImage
static float* resizeFloat(const float *src, size_t srcW, size_t srcH, size_t dstW, size_t dstH) {
    float *dst = (float *)malloc(dstW * dstH * sizeof(float));
    if (!dst) return NULL;

    vImage_Buffer srcBuf = { (void*)src, srcH, srcW, srcW * sizeof(float) };
    vImage_Buffer dstBuf = { dst,        dstH, dstW, dstW * sizeof(float) };
    vImageScale_PlanarF(&srcBuf, &dstBuf, NULL, kvImageEdgeExtend);
    return dst;
}

// Normalized cross-correlation score for one placement using vDSP
static float nccScore(const float *img, size_t imgW,
                      const float *tmpl, size_t tw, size_t th,
                      size_t x, size_t y) {
    size_t n = tw * th;
    float *patch = (float *)malloc(n * sizeof(float));
    if (!patch) return -1.0f;

    for (size_t row = 0; row < th; row++)
        memcpy(patch + row * tw, img + (y + row) * imgW + x, tw * sizeof(float));

    float patchMean, tmplMean;
    vDSP_meanv(patch, 1, &patchMean, n);
    vDSP_meanv(tmpl,  1, &tmplMean,  n);

    // Subtract means
    float negPatchMean = -patchMean, negTmplMean = -tmplMean;
    vDSP_vsadd(patch, 1, &negPatchMean, patch, 1, n);
    float *tmplCentered = (float *)malloc(n * sizeof(float));
    memcpy(tmplCentered, tmpl, n * sizeof(float));
    vDSP_vsadd(tmplCentered, 1, &negTmplMean, tmplCentered, 1, n);

    float dotProduct, patchNorm, tmplNorm;
    vDSP_dotpr(patch, 1, tmplCentered, 1, &dotProduct, n);
    vDSP_svesq(patch,        1, &patchNorm, n);
    vDSP_svesq(tmplCentered, 1, &tmplNorm,  n);

    free(patch);
    free(tmplCentered);

    float denom = sqrtf(patchNorm * tmplNorm);
    if (denom < 1e-6f) return 0.0f;
    return dotProduct / denom;
}

@interface TemplateMatch() {
    int _maxTryTimes;
    float _acceptableValue;
    float _scaleRation;
}
@end

@implementation TemplateMatch

- (instancetype)init {
    self = [super init];
    _maxTryTimes = 4;
    _acceptableValue = 0.8f;
    _scaleRation = 0.8f;
    return self;
}

- (void)setAcceptableValue:(float)av { _acceptableValue = av; }
- (void)setMaxTryTimes:(int)mtt     { _maxTryTimes = mtt; }
- (void)setScaleRation:(float)sr    { _scaleRation = sr; }

- (CGRect)templateMatchWithCGImage:(CGImageRef)img templatePath:(NSString*)templatePath error:(NSError**)err {
    size_t imgW, imgH;
    float *imgGray = cgImageToGrayscaleFloat(img, &imgW, &imgH);
    if (!imgGray) {
        *err = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999
                userInfo:@{NSLocalizedDescriptionKey:@"-1;;image_match: failed to convert screenshot to grayscale\r\n"}];
        return CGRectZero;
    }

    size_t tmplW, tmplH;
    float *tmplGray = loadImageToGrayscaleFloat(templatePath, &tmplW, &tmplH);
    if (!tmplGray) {
        free(imgGray);
        *err = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999
                userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:
                    @"-1;;image_match: failed to load template: %@\r\n", templatePath]}];
        return CGRectZero;
    }

    CGRect best = CGRectZero;
    float bestScore = -1.0f;
    size_t bestTW = tmplW, bestTH = tmplH;

    // Try original size + scaled variants (same logic as original OpenCV version)
    NSMutableArray *scales = [NSMutableArray array];
    [scales addObject:@(1.0f)];
    for (int i = 0; i < _maxTryTimes; i++) {
        [scales addObject:@(powf(2.0f - _scaleRation, i + 1))];
        [scales addObject:@(powf(_scaleRation, i + 1))];
    }

    for (NSNumber *scaleNum in scales) {
        float scale = scaleNum.floatValue;
        size_t tw = (size_t)(tmplW * scale);
        size_t th = (size_t)(tmplH * scale);
        if (tw < 2 || th < 2 || tw >= imgW || th >= imgH) continue;

        float *tmplScaled;
        if (scale == 1.0f) {
            tmplScaled = tmplGray;
        } else {
            tmplScaled = resizeFloat(tmplGray, tmplW, tmplH, tw, th);
            if (!tmplScaled) continue;
        }

        // Step through image — skip every 2px for speed, refine around best
        size_t step = MAX(1, MIN(tw, th) / 8);
        for (size_t y = 0; y + th <= imgH; y += step) {
            for (size_t x = 0; x + tw <= imgW; x += step) {
                float score = nccScore(imgGray, imgW, tmplScaled, tw, th, x, y);
                if (score > bestScore) {
                    bestScore = score;
                    best = CGRectMake(x, y, tw, th);
                    bestTW = tw; bestTH = th;
                }
            }
        }

        if (scale != 1.0f) free(tmplScaled);

        if (bestScore >= _acceptableValue) break;
    }

    free(imgGray);
    free(tmplGray);

    if (bestScore >= _acceptableValue) {
        // Refine at step=1 around best location
        size_t rx = (best.origin.x > 4) ? best.origin.x - 4 : 0;
        size_t ry = (best.origin.y > 4) ? best.origin.y - 4 : 0;
        size_t rxMax = MIN(rx + bestTW + 8, imgW - bestTW);
        size_t ryMax = MIN(ry + bestTH + 8, imgH - bestTH);
        // Reload for refinement pass
        float *imgGray2 = cgImageToGrayscaleFloat(img, &imgW, &imgH);
        float *tmplGray2 = loadImageToGrayscaleFloat(templatePath, &tmplW, &tmplH);
        if (imgGray2 && tmplGray2) {
            float *tmplS = (bestTW == tmplW && bestTH == tmplH) ? tmplGray2
                : resizeFloat(tmplGray2, tmplW, tmplH, bestTW, bestTH);
            for (size_t y = ry; y <= ryMax; y++) {
                for (size_t x = rx; x <= rxMax; x++) {
                    float score = nccScore(imgGray2, imgW, tmplS, bestTW, bestTH, x, y);
                    if (score > bestScore) {
                        bestScore = score;
                        best = CGRectMake(x, y, bestTW, bestTH);
                    }
                }
            }
            if (tmplS != tmplGray2) free(tmplS);
        }
        if (imgGray2) free(imgGray2);
        if (tmplGray2) free(tmplGray2);

        NSLog(@"com.zjx.springboard: image_match success. x:%.0f y:%.0f w:%.0f h:%.0f score:%.3f",
              best.origin.x, best.origin.y, best.size.width, best.size.height, bestScore);
        return best;
    }

    NSLog(@"com.zjx.springboard: image_match failed. best score: %.3f", bestScore);
    *err = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999
            userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:
                @"-1;;image_match: no match found (best score: %.3f, required: %.3f)\r\n",
                bestScore, _acceptableValue]}];
    return CGRectZero;
}

@end
