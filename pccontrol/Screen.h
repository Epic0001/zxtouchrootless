#ifndef SCREEN_H
#define SCREEN_H

#import <UIKit/UIKit.h>


@interface Screen :NSObject
{
    
}

+ (void)setScreenSize:(CGFloat)x height:(CGFloat) y;
+ (int)getScreenOrientation;
+ (CGFloat)getScreenWidth;
+ (CGFloat)getScreenHeight;
+ (CGFloat)getScale;
+ (NSString*)screenShot;
+ (CGRect)getBounds;
+ (NSString*)screenShotAlwaysUp;
+ (UIImage*)screenShotUIImage;
+ (void)releaseUIImage:(UIImage**)img;
+ (CGImageRef)createScreenShotCGImageRef;

@end

#endif
