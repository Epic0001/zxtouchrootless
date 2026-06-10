#ifndef TOUCH_INDICATOR_VIEW_LIST_H
#define TOUCH_INDICATOR_VIEW_LIST_H

#import "TouchIndicatorView.h"

@interface TouchIndicatorViewList : NSObject
{

}

- (int)count;
- (TouchIndicatorView*)get:(int)index;

@end

#endif
