#import "Popup.h"
#include <rootless.h>
#import "Screen.h"
#import "Record.h"
#include "Play.h"
#include "AlertBox.h"
#include "Toast.h"
#import <UIKit/UIKit.h>

extern CGFloat device_screen_width;
extern CGFloat device_screen_height;

static int windowWidth = 250;
static int windowHeight = 250;

@implementation PopupWindow
{
    UIWindow *_window;
    BOOL isShown;
}

- (id) init
{
    self = [super init];
    if(self)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat screenWidth = [Screen getScreenWidth];
            CGFloat screenHeight = [Screen getScreenHeight];

            CGFloat scale = [Screen getScale];

            windowWidth = (int)((screenWidth/scale)/1.7);
            //windowHeight = (int)((screenHeight/scale)/4);

            int windowLeftTopCornerX = (int)((screenWidth/scale)/2 - windowWidth/2);
            int windowLeftTopCornerY = (int)((screenHeight/scale)/2 - windowHeight/2);
            // iOS 13+ requires UIWindowScene
            UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
            if (scene) {
                _window = [[UIWindow alloc] initWithWindowScene:scene];
                _window.frame = CGRectMake(windowLeftTopCornerX, windowLeftTopCornerY, windowWidth, windowHeight);
            } else {
                _window = [[UIWindow alloc] initWithFrame:CGRectMake(windowLeftTopCornerX, windowLeftTopCornerY, windowWidth, windowHeight)];
            }
            _window.windowLevel = UIWindowLevelAlert + 1;
            UIViewController *rootVC = [[UIViewController alloc] init];
            rootVC.view.backgroundColor = [UIColor whiteColor];
            rootVC.view.layer.borderColor = [UIColor lightGrayColor].CGColor;
            rootVC.view.layer.borderWidth = 2.0f;
            rootVC.view.layer.cornerRadius = 15.0f;
            rootVC.view.clipsToBounds = YES;
            _window.rootViewController = rootVC;
            UIView *contentView = rootVC.view;

            // Add header
            NSString *headerText = @"ZXTouch Panel";
            UIFont *font = [UIFont boldSystemFontOfSize:16];
            UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 8, windowWidth - 40, 25)];
            headerLabel.font = font;
            headerLabel.text = headerText;
            headerLabel.textColor = [UIColor blackColor];
            headerLabel.backgroundColor = [UIColor clearColor];
            [contentView addSubview:headerLabel];

            // Close button
            UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
            [closeButton setTitle:@"✕" forState:UIControlStateNormal];
            closeButton.frame = CGRectMake(windowWidth - 35, 5, 30, 30);
            [contentView addSubview:closeButton];

            // REC button
            UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [recordButton addTarget:self action:@selector(recordingStart) forControlEvents:UIControlEventTouchUpInside];
            [recordButton setTitle:@"⏺ REC" forState:UIControlStateNormal];
            [recordButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            recordButton.frame = CGRectMake(10, 45, 90, 40);
            recordButton.layer.borderColor = [UIColor redColor].CGColor;
            recordButton.layer.borderWidth = 1.0f;
            recordButton.layer.cornerRadius = 8.0f;
            [contentView addSubview:recordButton];

            // STOP button
            UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [stopButton addTarget:self action:@selector(stopPlaying) forControlEvents:UIControlEventTouchUpInside];
            [stopButton setTitle:@"⏹ STOP" forState:UIControlStateNormal];
            [stopButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            stopButton.frame = CGRectMake(110, 45, 90, 40);
            stopButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
            stopButton.layer.borderWidth = 1.0f;
            stopButton.layer.cornerRadius = 8.0f;
            [contentView addSubview:stopButton];
        });
        isShown = NO;        
    }
    return self;
}

- (void) recordingStart {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self hide];
        NSError *err = nil;
        startRecording(0, &err);
        if (err)
        {
            showAlertBox(@"Error", [NSString stringWithFormat:@"Unable to start recording. Reason: %@",[err localizedDescription]], 999);
            return;
        }
    });
}

- (void) stopPlaying {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *err = nil;
        stopScriptPlaying(&err);
        if (err)
        {
            showAlertBox(@"Error", [NSString stringWithFormat:@"Error happens while trying to stop script. %@", err], 999);
        }
        else
        {
            [Toast showToastWithContent:@"Script has been stopped" type:4 duration:1.0f position:0 fontSize:0];
        }
    });
}

- (void) show {
    dispatch_async(dispatch_get_main_queue(), ^{
        _window.hidden = NO;
    });
    isShown = YES;
}

- (void) hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        _window.hidden = YES;
    });
    isShown = NO;
}

- (BOOL) isShown {
    return isShown;
}
@end
