#import "Popup.h"
#include <rootless.h>
#import "Screen.h"
#import "Record.h"
#include "Play.h"
#include "AlertBox.h"
#include "Toast.h"
#include "Common.h"
#import <UIKit/UIKit.h>

#define PANEL_WIDTH  260
#define PANEL_HEIGHT 340
#define BTN_H 38

@implementation PopupWindow
{
    UIWindow *_window;
    UIScrollView *_scriptScrollView;
    BOOL isShown;
}

- (id) init
{
    self = [super init];
    if (self)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
            CGRect screenBounds = [UIScreen mainScreen].bounds;
            CGFloat cx = CGRectGetMidX(screenBounds) - PANEL_WIDTH / 2.0;
            CGFloat cy = CGRectGetMidY(screenBounds) - PANEL_HEIGHT / 2.0;

            if (scene) {
                _window = [[UIWindow alloc] initWithWindowScene:scene];
                _window.frame = CGRectMake(cx, cy, PANEL_WIDTH, PANEL_HEIGHT);
            } else {
                _window = [[UIWindow alloc] initWithFrame:CGRectMake(cx, cy, PANEL_WIDTH, PANEL_HEIGHT)];
            }
            _window.windowLevel = UIWindowLevelAlert + 1;

            UIViewController *rootVC = [[UIViewController alloc] init];
            rootVC.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
            rootVC.view.layer.cornerRadius = 16.0f;
            rootVC.view.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
            rootVC.view.layer.borderWidth = 1.0f;
            rootVC.view.clipsToBounds = YES;
            _window.rootViewController = rootVC;
            UIView *cv = rootVC.view;

            // Header
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 10, PANEL_WIDTH - 50, 28)];
            title.text = @"ZXTouch";
            title.font = [UIFont boldSystemFontOfSize:18];
            title.textColor = [UIColor blackColor];
            [cv addSubview:title];

            // Close button
            UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
            [closeBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
            closeBtn.frame = CGRectMake(PANEL_WIDTH - 42, 6, 36, 36);
            closeBtn.titleLabel.font = [UIFont systemFontOfSize:18];
            [cv addSubview:closeBtn];

            // Separator
            UIView *sep1 = [[UIView alloc] initWithFrame:CGRectMake(0, 46, PANEL_WIDTH, 1)];
            sep1.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
            [cv addSubview:sep1];

            // REC button
            UIButton *recBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [recBtn setTitle:@"⏺  REC" forState:UIControlStateNormal];
            [recBtn setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
            recBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            recBtn.frame = CGRectMake(8, 54, (PANEL_WIDTH - 24) / 2, BTN_H);
            recBtn.backgroundColor = [UIColor colorWithRed:1 green:0.93 blue:0.93 alpha:1];
            recBtn.layer.cornerRadius = 8;
            recBtn.layer.borderColor = [UIColor systemRedColor].CGColor;
            recBtn.layer.borderWidth = 1;
            [recBtn addTarget:self action:@selector(recordingStart) forControlEvents:UIControlEventTouchUpInside];
            [cv addSubview:recBtn];

            // STOP button
            UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            [stopBtn setTitle:@"⏹  STOP" forState:UIControlStateNormal];
            [stopBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            stopBtn.titleLabel.font = [UIFont systemFontOfSize:15];
            stopBtn.frame = CGRectMake(PANEL_WIDTH / 2 + 4, 54, (PANEL_WIDTH - 24) / 2, BTN_H);
            stopBtn.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1.0];
            stopBtn.layer.cornerRadius = 8;
            [stopBtn addTarget:self action:@selector(stopPlaying) forControlEvents:UIControlEventTouchUpInside];
            [cv addSubview:stopBtn];

            // Separator
            UIView *sep2 = [[UIView alloc] initWithFrame:CGRectMake(0, 54 + BTN_H + 8, PANEL_WIDTH, 1)];
            sep2.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
            [cv addSubview:sep2];

            // Scripts label
            UILabel *scriptsLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 54 + BTN_H + 14, PANEL_WIDTH - 20, 20)];
            scriptsLabel.text = @"Scripts";
            scriptsLabel.font = [UIFont boldSystemFontOfSize:13];
            scriptsLabel.textColor = [UIColor grayColor];
            [cv addSubview:scriptsLabel];

            // Script scroll view
            CGFloat scrollTop = 54 + BTN_H + 38;
            _scriptScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, scrollTop, PANEL_WIDTH, PANEL_HEIGHT - scrollTop - 8)];
            _scriptScrollView.backgroundColor = [UIColor clearColor];
            [cv addSubview:_scriptScrollView];
        });
        isShown = NO;
    }
    return self;
}

- (void) refreshScriptList {
    NSString *scriptsPath = getScriptsFolder();
    NSError *err = nil;
    NSArray *scripts = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:scriptsPath error:&err];
    NSArray *sorted = scripts ? [scripts sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] : @[];

    dispatch_async(dispatch_get_main_queue(), ^{
        // Remove existing script buttons
        for (UIView *v in _scriptScrollView.subviews) [v removeFromSuperview];

        CGFloat y = 4;
        CGFloat btnW = PANEL_WIDTH - 16;
        for (NSString *scriptName in sorted) {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
            NSString *display = [scriptName hasSuffix:@".bdl"] ?
                [scriptName substringToIndex:scriptName.length - 4] : scriptName;
            [btn setTitle:display forState:UIControlStateNormal];
            btn.titleLabel.font = [UIFont systemFontOfSize:14];
            btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            btn.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
            btn.frame = CGRectMake(8, y, btnW, BTN_H);
            btn.backgroundColor = [UIColor whiteColor];
            btn.layer.cornerRadius = 8;
            btn.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
            btn.layer.borderWidth = 1;

            NSString *fullPath = [scriptsPath stringByAppendingPathComponent:scriptName];
            [btn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                [self hide];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSError *playErr = nil;
                    playScript((UInt8*)[fullPath UTF8String], &playErr);
                    if (playErr) showAlertBox(@"Error", [playErr localizedDescription], 999);
                });
            }] forControlEvents:UIControlEventTouchUpInside];

            [_scriptScrollView addSubview:btn];
            y += BTN_H + 6;
        }
        _scriptScrollView.contentSize = CGSizeMake(PANEL_WIDTH, y + 4);
    });
}

- (void) recordingStart {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self hide];
        NSError *err = nil;
        startRecording(0, &err);
        if (err)
            showAlertBox(@"Error", [NSString stringWithFormat:@"Unable to start recording: %@", [err localizedDescription]], 999);
    });
}

- (void) stopPlaying {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *err = nil;
        stopScriptPlaying(&err);
        if (err)
            showAlertBox(@"Error", [NSString stringWithFormat:@"Stop error: %@", err], 999);
        else
            [Toast showToastWithContent:@"Script stopped" type:4 duration:1.0f position:0 fontSize:0];
    });
}

- (void) show {
    [self refreshScriptList];
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
