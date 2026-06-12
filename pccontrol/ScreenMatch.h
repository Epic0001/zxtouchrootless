#ifndef SCREEN_MATCH_H
#define SCREEN_MATCH_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

CGRect screenMatchFromRawData(UInt8 *eventData, NSError **error);

@interface ScreenMatch : NSObject
+ (CGRect)matchCurrentScreenWithTemplate:(NSString*)templatePath maxTryTimes:(int)mtt acceptableValue:(float)av scaleRation:(float)sr error:(NSError**)err;
@end

#endif
