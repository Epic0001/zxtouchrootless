#ifndef TOUCH_INDICATOR_VIEW_H
#define TOUCH_INDICATOR_VIEW_H

#import <UIKit/UIKit.h>

#define INDICATOR_VIEW_DEFAULT_SIZE 60
#define SIZE_INDIACTOR_TOUCH_RADIUS_RATIO 1590

@interface TouchIndicatorView : UIView
@property (weak, nonatomic) NSString* fingerIndex;

-(void)dealloc;

@end

#endif
