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

void showAlertBox(NSString* title, NSString* content, int dismissTime)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:title
            message:content
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault handler:nil]];

        // Find a view controller that can present
        UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
        UIViewController *presenter = scene.windows.lastObject.rootViewController;
        while (presenter.presentedViewController)
            presenter = presenter.presentedViewController;

        [presenter presentViewController:alert animated:YES completion:nil];

        // Auto-dismiss after dismissTime seconds if > 0
        if (dismissTime > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(dismissTime * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    [alert dismissViewControllerAnimated:YES completion:nil];
                });
        }
    });
}
