#ifndef POPUP_H
#define POPUP_H

#import <Foundation/Foundation.h>

@interface PopupWindow : NSObject
- (void) show;
- (void) hide;
- (void) setDarkMode:(BOOL)dark;
- (BOOL) isShown;
@end

void applyPanelDarkMode(BOOL dark);

#endif