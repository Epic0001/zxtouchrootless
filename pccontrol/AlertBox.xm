#include "AlertBox.h"
#include "SocketServer.h"
#import <UIKit/UIKit.h>

// Dedicated window for hosting alert controllers (survives until dismissed)
static NSMutableArray *_alertWindows = nil;

void showAlertBoxFromRawData(UInt8 *eventData, NSError **error)
{
    NSString *alertData = [NSString stringWithUTF8String:(char*)eventData];
    NSArray *alertDataArray = [alertData componentsSeparatedByString:@";;"];
    if ([alertDataArray count] < 3)
    {
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Unable to show alert box. The socket format should be title;;content;;duration.\r\n"}];
        return;
    }
    showAlertBox(alertDataArray[0], alertDataArray[1], [alertDataArray[2] intValue]);
}

NSString *promptInputFromRawData(UInt8 *eventData, NSError **error)
{
    NSString *promptData = [NSString stringWithUTF8String:(char*)eventData] ?: @"";
    NSArray *parts = [promptData componentsSeparatedByString:@";;"];
    NSString *title = parts.count > 0 && [parts[0] length] ? parts[0] : @"ZXTouch";
    NSString *message = parts.count > 1 ? parts[1] : @"";
    NSString *placeholder = parts.count > 2 ? parts[2] : @"";
    NSString *defaultValue = parts.count > 3 ? parts[3] : @"";

    __block NSString *result = nil;
    __block BOOL cancelled = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_alertWindows) _alertWindows = [NSMutableArray array];

        UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
        UIWindow *win = scene ? [[UIWindow alloc] initWithWindowScene:scene] : [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        win.windowLevel = UIWindowLevelAlert + 4;
        UIViewController *rvc = [[UIViewController alloc] init];
        rvc.view.backgroundColor = [UIColor clearColor];
        win.rootViewController = rvc;
        [win makeKeyAndVisible];
        [_alertWindows addObject:win];

        void (^cleanup)(void) = ^{
            win.hidden = YES;
            [_alertWindows removeObject:win];
            dispatch_semaphore_signal(sema);
        };

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = placeholder;
            textField.text = defaultValue;
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            cancelled = YES;
            cleanup();
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            result = alert.textFields.firstObject.text ?: @"";
            cleanup();
        }]];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [rvc presentViewController:alert animated:YES completion:nil];
        });
    });

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    if (cancelled) {
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;User cancelled input prompt.\r\n"}];
        return @"";
    }
    return result ?: @"";
}

void showAlertBox(NSString* title, NSString* content, int dismissTime)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_alertWindows) _alertWindows = [NSMutableArray array];

        UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
        UIWindow *win;
        if (scene) {
            win = [[UIWindow alloc] initWithWindowScene:scene];
        } else {
            win = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        win.windowLevel = UIWindowLevelAlert + 3;
        UIViewController *rvc = [[UIViewController alloc] init];
        rvc.view.backgroundColor = [UIColor clearColor];
        win.rootViewController = rvc;
        [win makeKeyAndVisible];
        [_alertWindows addObject:win];

        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:title
            message:content
            preferredStyle:UIAlertControllerStyleAlert];

        void (^cleanup)(void) = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                win.hidden = YES;
                [_alertWindows removeObject:win];
            });
        };

        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *a) { cleanup(); }]];

        // Small delay so the window's root VC finishes appearing before we present
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
                [rvc presentViewController:alert animated:YES completion:nil];
                if (dismissTime > 0) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dismissTime * NSEC_PER_SEC)),
                        dispatch_get_main_queue(), ^{
                            [alert dismissViewControllerAnimated:YES completion:cleanup];
                        });
                }
            });
    });
}
