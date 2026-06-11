#import "Popup.h"
#include <rootless.h>
#import "Screen.h"
#import "Record.h"
#include "Play.h"
#include "AlertBox.h"
#include "Toast.h"
#include "Common.h"
#include "Config.h"
#import <UIKit/UIKit.h>

#define BTN_H 38
#define SETTINGS_KEY_REPEAT  @"repeat_times"
#define SETTINGS_KEY_SPEED   @"speed"
#define SETTINGS_KEY_INTERVAL @"interval"

static UIButton* makeBtn(NSString *title, UIColor *color) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:14];
    b.backgroundColor = [UIColor secondarySystemBackgroundColor];
    b.layer.cornerRadius = 8;
    b.layer.borderColor = color.CGColor;
    b.layer.borderWidth = 1;
    [b setTitleColor:color forState:UIControlStateNormal];
    return b;
}

static UIView* makeSep() {
    UIView *s = [[UIView alloc] init];
    s.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    return s;
}

@implementation PopupWindow
{
    UIWindow       *_window;
    UIScrollView   *_scriptScrollView;
    UIButton       *_gearBtn;
    int             _repeatCount;
    float           _speed;
    float           _interval;
    BOOL            _settingsVisible;  // whether to show settings dialog before playing
    BOOL            isShown;
}

- (id) init {
    self = [super init];
    if (self) {
        _repeatCount = 0;
        _speed = 1.0f;
        _interval = 0.0f;
        _settingsVisible = NO;
        isShown = NO;
        [self buildWindow];
    }
    return self;
}

- (void) buildWindow {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect sb = [UIScreen mainScreen].bounds;
        CGFloat shortSide = MIN(sb.size.width, sb.size.height);
        CGFloat longSide  = MAX(sb.size.width, sb.size.height);
        CGFloat pw = shortSide * 0.65f;
        pw = MAX(pw, 220); pw = MIN(pw, 320);
        CGFloat ph = longSide * 0.55f;
        ph = MAX(ph, 280); ph = MIN(ph, 420);
        CGFloat cx = CGRectGetMidX(sb) - pw/2;
        CGFloat cy = CGRectGetMidY(sb) - ph/2;

        UIWindowScene *scene = (UIWindowScene *)[[UIApplication sharedApplication].connectedScenes anyObject];
        if (scene) {
            _window = [[UIWindow alloc] initWithWindowScene:scene];
            _window.frame = CGRectMake(cx, cy, pw, ph);
        } else {
            _window = [[UIWindow alloc] initWithFrame:CGRectMake(cx, cy, pw, ph)];
        }
        _window.windowLevel = UIWindowLevelAlert + 1;
        _window.autoresizingMask = UIViewAutoresizingNone; // prevent auto-stretch on rotation

        UIViewController *rvc = [[UIViewController alloc] init];
        rvc.view.backgroundColor = [UIColor systemBackgroundColor];
        rvc.view.layer.cornerRadius = 16;
        rvc.view.layer.borderColor = [UIColor separatorColor].CGColor;
        rvc.view.layer.borderWidth = 1;
        rvc.view.clipsToBounds = YES;
        _window.rootViewController = rvc;
        UIView *cv = rvc.view;

        // Header
        UILabel *ttl = [[UILabel alloc] initWithFrame:CGRectMake(12,10,pw-100,28)];
        ttl.text = @"ZXTouch"; ttl.font = [UIFont boldSystemFontOfSize:17];
        ttl.textColor = [UIColor labelColor]; [cv addSubview:ttl];

        // ⚙️ toggle — tap to enable/disable "ask settings before play"
        _gearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_gearBtn setTitle:@"⚙️" forState:UIControlStateNormal];
        _gearBtn.frame = CGRectMake(pw-80, 6, 36, 36);
        _gearBtn.layer.cornerRadius = 8;
        [_gearBtn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
            _settingsVisible = !_settingsVisible;
            _gearBtn.backgroundColor = _settingsVisible ?
                [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.25] :
                [UIColor clearColor];
        }] forControlEvents:UIControlEventTouchUpInside];
        [cv addSubview:_gearBtn];

        // Close button
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
        closeBtn.frame = CGRectMake(pw-42, 6, 36, 36);
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        [closeBtn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
            [self hide];
        }] forControlEvents:UIControlEventTouchUpInside];
        [cv addSubview:closeBtn];

        [cv addSubview:[self makeSepAt:CGRectMake(0,46,pw,1)]];

        // REC / STOP buttons
        CGFloat btnW = (pw - 24) / 2;
        UIButton *recBtn = makeBtn(@"⏺  REC", [UIColor systemRedColor]);
        recBtn.frame = CGRectMake(8, 54, btnW, BTN_H);
        recBtn.backgroundColor = [UIColor.systemRedColor colorWithAlphaComponent:0.12];
        [recBtn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
            [self recordingStart];
        }] forControlEvents:UIControlEventTouchUpInside];
        [cv addSubview:recBtn];

        UIButton *stopBtn = makeBtn(@"⏹  STOP", [UIColor darkGrayColor]);
        stopBtn.frame = CGRectMake(pw/2+4, 54, btnW, BTN_H);
        [stopBtn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
            [self stopPlaying];
        }] forControlEvents:UIControlEventTouchUpInside];
        [cv addSubview:stopBtn];

        [cv addSubview:[self makeSepAt:CGRectMake(0, 54+BTN_H+8, pw, 1)]];

        // Scripts label — shows hint when settings mode on
        UILabel *sl = [[UILabel alloc] initWithFrame:CGRectMake(12, 54+BTN_H+14, pw-20, 18)];
        sl.text = @"Scripts"; sl.font = [UIFont boldSystemFontOfSize:12];
        sl.textColor = [UIColor secondaryLabelColor]; [cv addSubview:sl];

        // Script scroll view
        CGFloat scrollTop = 54+BTN_H+36;
        _scriptScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,scrollTop,pw,ph-scrollTop-8)];
        _scriptScrollView.backgroundColor = [UIColor clearColor];
        [cv addSubview:_scriptScrollView];

        // Reposition on rotation
        [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
            object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                if (isShown) [self repositionWindow];
            }];
    });
}

- (UIView*) makeSepAt:(CGRect)r {
    UIView *s = [[UIView alloc] initWithFrame:r];
    s.backgroundColor = [UIColor separatorColor];
    return s;
}

void applyPanelDarkMode(BOOL dark) {
    extern PopupWindow *popupWindow;
    if (popupWindow) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [popupWindow setDarkMode:dark];
        });
    }
}



- (void) repositionWindow {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect sb = [UIScreen mainScreen].bounds;
        CGFloat shortSide = MIN(sb.size.width, sb.size.height);
        CGFloat longSide  = MAX(sb.size.width, sb.size.height);
        CGFloat pw = shortSide * 0.65f;
        pw = MAX(pw, 220); pw = MIN(pw, 320);
        CGFloat ph = longSide * 0.55f;
        ph = MAX(ph, 280); ph = MIN(ph, 420);
        CGFloat cx = CGRectGetMidX(sb) - pw/2;
        CGFloat cy = CGRectGetMidY(sb) - ph/2;
        _window.frame = CGRectMake(cx, cy, pw, ph);
        // Resize scrollview to fill to the bottom of the new window height
        if (_scriptScrollView) {
            CGFloat scrollTop = _scriptScrollView.frame.origin.y;
            _scriptScrollView.frame = CGRectMake(0, scrollTop, pw, ph - scrollTop - 8);
        }
    });
}

- (void) populateScrollView:(NSArray<NSDictionary*>*)items {
    for (UIView *v in _scriptScrollView.subviews) [v removeFromSuperview];
    CGFloat pw = _window.frame.size.width;
    if (pw < 10) pw = 260;
    CGFloat y = 4;
    for (NSDictionary *item in items) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:item[@"label"] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.frame = CGRectMake(8, y, pw - 16, BTN_H);
        btn.backgroundColor = [UIColor secondarySystemBackgroundColor];
        btn.layer.cornerRadius = 8;
        btn.layer.borderColor = [UIColor separatorColor].CGColor;
        btn.layer.borderWidth = 1;
        NSString *action = item[@"action"];
        if ([action isEqualToString:@"folder"]) {
            [btn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
            NSString *fp = item[@"path"], *fn = item[@"folderName"];
            [btn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
                [self showFolder:fp name:fn];
            }] forControlEvents:UIControlEventTouchUpInside];
        } else if ([action isEqualToString:@"back"]) {
            [btn setTitleColor:[UIColor systemOrangeColor] forState:UIControlStateNormal];
            [btn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
                [self refreshScriptList];
            }] forControlEvents:UIControlEventTouchUpInside];
        } else {
            NSString *fullPath = item[@"path"];
            [btn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
                if (_settingsVisible) {
                    UIAlertController *alert = [UIAlertController
                        alertControllerWithTitle:@"Play Settings"
                        message:item[@"label"]
                        preferredStyle:UIAlertControllerStyleAlert];
                    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                        tf.placeholder = @"Repeat count (e.g. 3)";
                        tf.keyboardType = UIKeyboardTypeNumberPad;
                        tf.text = _repeatCount > 0 ? [NSString stringWithFormat:@"%d", _repeatCount] : @"";
                    }];
                    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                        tf.placeholder = @"Speed (e.g. 1.0)";
                        tf.keyboardType = UIKeyboardTypeDecimalPad;
                        tf.text = [NSString stringWithFormat:@"%.1f", _speed];
                    }];
                    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
                        tf.placeholder = @"Interval between runs in sec (e.g. 0)";
                        tf.keyboardType = UIKeyboardTypeDecimalPad;
                        tf.text = _interval > 0 ? [NSString stringWithFormat:@"%.1f", _interval] : @"";
                    }];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Run" style:UIAlertActionStyleDefault handler:^(UIAlertAction *aa) {
                        NSString *repeatStr  = alert.textFields[0].text;
                        NSString *speedStr   = alert.textFields[1].text;
                        NSString *intervalStr = alert.textFields[2].text;
                        int repeat   = (repeatStr.length > 0)   ? [repeatStr intValue]      : 0;
                        float sp     = (speedStr.length > 0)    ? [speedStr floatValue]     : 1.0f;
                        float intv   = (intervalStr.length > 0) ? [intervalStr floatValue]  : 0.0f;
                        if (sp <= 0) sp = 1.0f;
                        _repeatCount = repeat; _speed = sp; _interval = intv;
                        [self hide];
                        [self saveSettings:_repeatCount speed:_speed interval:_interval];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            NSError *err = nil;
                            playScript((UInt8*)[fullPath UTF8String], &err);
                            if (err) showAlertBox(@"Error", [err localizedDescription], 999);
                        });
                    }]];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_window.rootViewController presentViewController:alert animated:YES completion:nil];
                    });
                } else {
                    // Direct play
                    [self hide];
                    [self saveSettings:_repeatCount speed:_speed interval:_interval];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSError *err = nil;
                        playScript((UInt8*)[fullPath UTF8String], &err);
                        if (err) showAlertBox(@"Error", [err localizedDescription], 999);
                    });
                }
            }] forControlEvents:UIControlEventTouchUpInside];
        }
        [_scriptScrollView addSubview:btn];
        y += BTN_H + 6;
    }
    _scriptScrollView.contentSize = CGSizeMake(pw, y + 4);
    [_scriptScrollView setContentOffset:CGPointZero animated:NO];
}

- (void) saveSettings:(int)repeat speed:(float)speed interval:(float)interval {
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    config[@"scriptPlaybackInfo"] = @{
        SETTINGS_KEY_REPEAT: @(repeat),
        SETTINGS_KEY_SPEED: @(speed),
        SETTINGS_KEY_INTERVAL: @(interval)
    };
    [config writeToFile:SCRIPT_PLAY_CONFIG_PATH atomically:YES];
}

- (void) showFolder:(NSString*)folderPath name:(NSString*)name {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *contents = [[fm contentsOfDirectoryAtPath:folderPath error:nil]
                         sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:@{@"label": @"← Back", @"action": @"back"}];
    for (NSString *n in contents) {
        if (![n hasSuffix:@".bdl"]) continue;
        NSString *path = [folderPath stringByAppendingPathComponent:n];
        [items addObject:@{@"label": [n substringToIndex:n.length-4], @"path": path, @"action": @"play"}];
    }
    dispatch_async(dispatch_get_main_queue(), ^{ [self populateScrollView:items]; });
}

- (void) refreshScriptList {
    NSString *base = getScriptsFolder();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *top = [[fm contentsOfDirectoryAtPath:base error:nil]
                    sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableArray *items = [NSMutableArray array];
    for (NSString *name in top) {
        NSString *path = [base stringByAppendingPathComponent:name];
        BOOL isDir = NO; [fm fileExistsAtPath:path isDirectory:&isDir];
        if ([name hasSuffix:@".bdl"]) {
            [items addObject:@{@"label": [name substringToIndex:name.length-4], @"path": path, @"action": @"play"}];
        } else if (isDir) {
            [items addObject:@{@"label": [NSString stringWithFormat:@"📁 %@", name], @"path": path, @"folderName": name, @"action": @"folder"}];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{ [self populateScrollView:items]; });
}

- (void) recordingStart {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self hide];
        NSError *err = nil;
        startRecording(0, &err);
        if (err) showAlertBox(@"Error", [NSString stringWithFormat:@"Unable to start recording: %@", [err localizedDescription]], 999);
    });
}

- (void) stopPlaying {
    if (!isScriptPlaying()) {
        // No script running — do nothing silently
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *err = nil;
        stopScriptPlaying(&err);
        // Don't show alert here — volume button handler shows it
    });
}

- (void) setDarkMode:(BOOL)dark {
    dispatch_async(dispatch_get_main_queue(), ^{
        _window.overrideUserInterfaceStyle = dark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
    });
}

- (void) show {
    [self refreshScriptList];
    [self repositionWindow];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Apply dark mode from config each time the panel opens
        NSDictionary *cfg = [[NSDictionary alloc] initWithContentsOfFile:SCRIPT_PLAY_CONFIG_PATH];
        NSDictionary *tweakCfg = nil;
        NSString *configFilePath = [NSString stringWithFormat:@"/var/mobile/Library/ZXTouch/config/tweak/config.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:configFilePath])
            tweakCfg = [[NSDictionary alloc] initWithContentsOfFile:configFilePath];
        BOOL dark = tweakCfg[@"dark_mode"] ? [tweakCfg[@"dark_mode"] boolValue] : NO;
        _window.overrideUserInterfaceStyle = dark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
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

- (BOOL) isShown { return isShown; }

@end
