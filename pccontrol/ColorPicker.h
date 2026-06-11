#ifndef COLOR_PICKER_H
#define COLOR_PICKER_H

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NSDictionary* getRGBFromRawData(UInt8 *eventData, NSError **error);
NSString* searchRGBFromRawData(UInt8 *eventData, NSError **error);

@interface ColorPicker : NSObject
{

}
+ (NSString*)searchRGBFromCGImageRef:(CGImageRef)img region:(CGRect)region redMin:(int)redMin redMax:(int)redMax greenMin:(int)greenMin greenMax:(int)greenMax blueMin:(int)blueMin blueMax:(int)blueMax skip:(int)skip;
+ (NSDictionary *)colorAtPositionFromCGImage:(CGImageRef)img x:(int)x andY:(int)y;

@end

#endif