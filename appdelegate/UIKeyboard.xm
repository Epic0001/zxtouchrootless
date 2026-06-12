#include "UIKeyboard.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CFMessagePort.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <execinfo.h>
#import <mach-o/dyld.h>
#include <substrate.h>

#define INSERT_TEXT 1
#define VIRTUAL_KEYBOARD 2
#define MOVE_CURSOR 3
#define DELETE_CHARACTER 4
#define PASTE_FROM_CLIPBOARD 5

#define TEST 99

#define VIRTUAL_KEYBOARD_HIDE 1
#define VIRTUAL_KEYBOARD_SHOW 2


@interface UIKeyboardImpl : UIView
	+ (id)sharedInstance;
	+ (id)activeInstance;
	- (void)insertText:(id)arg1;
	- (void)hideKeyboard;
    - (void)showKeyboard;
	- (void)clearDelegate;
	- (void)clearInput;
	- (void)moveSelectionToEndOfWord;
	- (void)moveCursorByAmount:(long long)arg1;
	- (void)deleteFromInput;
	- (void)clearSelection;
    - (void)deleteBackward;
 	- (void)setSelectionWithPoint:(struct CGPoint)arg1;
    - (id)markedText;
    - (void)unmarkText;
    - (void)clearSelection;
    - (void)setInputPoint:(struct CGPoint)arg1;
    - (_Bool)hasMarkedText;

 	@property (readonly, assign, nonatomic) UIResponder <UITextInput> *inputDelegate;
@end


%hook UIKeyboardImpl

    - (id)initWithFrame:(CGRect)arg1 forCustomInputView:(UIView*)view
    {
        // Don't register in SpringBoard — keyboard commands are sent FROM SpringBoard, not received
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            [[NSDistributedNotificationCenter defaultCenter]
                addObserver:self selector:@selector(handleKeyboardNotification:)
                name:@"com.zjx.zxtouch.keyboardcontrol" object:nil];
        }
		return %orig;
    }

	- (id)initWithFrame:(CGRect)arg1 {
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
            [[NSDistributedNotificationCenter defaultCenter]
                addObserver:self selector:@selector(handleKeyboardNotification:)
                name:@"com.zjx.zxtouch.keyboardcontrol" object:nil];
        }
		return %orig;
	}

	- (void)dealloc {
        [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.zjx.zxtouch.textinput" object:nil];
		//NSLog(@"com.zjx.appdelegate: UIKeyboardImpl instance deallocated");
		return %orig;
	}

    %new
	- (void)handleKeyboardNotification:(NSNotification *)notification {
		//NSLog(@"com.zjx.appdelegate: keyboard related notification received. %@", notification);
		NSDictionary *data = (NSDictionary*)notification.userInfo;

        int taskId = [data[@"task_id"] intValue];
		if (taskId == INSERT_TEXT)
		{
            NSString *content = data[@"task_content"] ?: @"";
            dispatch_async(dispatch_get_main_queue(), ^{
                // Try first responder directly (more reliable on iOS 16)
                BOOL inserted = NO;
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (![scene isKindOfClass:[UIWindowScene class]]) continue;
                    for (UIWindow *win in ((UIWindowScene *)scene).windows) {
                        UIResponder *r = [win performSelector:@selector(firstResponder)];
                        if (r && [r respondsToSelector:@selector(insertText:)]) {
                            [(id)r insertText:content];
                            inserted = YES;
                            break;
                        }
                    }
                    if (inserted) break;
                }
                // Fallback to UIKeyboardImpl
                if (!inserted && [self respondsToSelector:@selector(insertText:)])
                    [self insertText:content];
            });
		}
        else if (taskId == VIRTUAL_KEYBOARD)
        {
            int status = [data[@"task_content"] intValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == VIRTUAL_KEYBOARD_HIDE && [self respondsToSelector:@selector(hideKeyboard)])
                    [self hideKeyboard];
                else if (status == VIRTUAL_KEYBOARD_SHOW && [self respondsToSelector:@selector(showKeyboard)])
                    [self showKeyboard];
            });
        }
        else if (taskId == MOVE_CURSOR)
        {
            long long moveAmount = [data[@"task_content"] longLongValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self respondsToSelector:@selector(moveCursorByAmount:)])
                    [self moveCursorByAmount:moveAmount];
            });
        }
        else if (taskId == DELETE_CHARACTER)
        {
            int n = [data[@"task_content"] intValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self respondsToSelector:@selector(deleteBackward)]) {
                    for (int i = 0; i < n; i++) [self deleteBackward];
                }
            });
        }
        else if (taskId == PASTE_FROM_CLIPBOARD)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self respondsToSelector:@selector(insertText:)])
                    [self insertText:[UIPasteboard generalPasteboard].string ?: @""];
            });
        }
	}

%end