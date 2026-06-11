#include "AlertBox.h"
#include "SocketServer.h"
#import <UIKit/UIKit.h>

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

// Dedicated window for hosting alert controllers (survives until dismissed)
static NSMutableArray *_alertWindows = nil;

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
        win.hidden = NO;
        [_alertWindows addObject:win];

        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:title
            message:content
            preferredStyle:UIAlertControllerStyleAlert];

        void (^cleanup)(void) = ^{
            [_alertWindows removeObject:win];
        };

        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *a) { cleanup(); }]];

        [rvc presentViewController:alert animated:YES completion:nil];

        if (dismissTime > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dismissTime * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    [alert dismissViewControllerAnimated:YES completion:cleanup];
                });
        }
    });
}
