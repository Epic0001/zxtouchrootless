#ifndef TOUCH_INDICATOR_COORDINATE_VIEW_H
#define TOUCH_INDICATOR_COORDINATE_VIEW_H

#import <UIKit/UIKit.h>

#define INDICATOR_VIEW_DEFAULT_SIZE 60
#define SIZE_INDIACTOR_TOUCH_RADIUS_RATIO 1590

@interface TouchIndicatorCoordinateView : UIView
@property (weak, nonatomic) UILabel* coordinateLabel;

-(void)dealloc;

@end

#endif
