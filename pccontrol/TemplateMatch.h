#ifndef TEMPLATE_MATCH_H
#define TEMPLATE_MATCH_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface TemplateMatch : NSObject

- (void)setAcceptableValue:(float)av;
- (void)setMaxTryTimes:(int)mtt;
- (void)setScaleRation:(float)sr;
- (CGRect)templateMatchWithCGImage:(CGImageRef)img templatePath:(NSString*)templatePath error:(NSError**)err;

@end

#endif
