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
    b.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
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
    UIView         *_settingsView;
    UILabel        *_repeatLabel;
    UILabel        *_speedLabel;
    int             _repeatCount;
    float           _speed;
    BOOL            _settingsVisible;
    BOOL            isShown;
}

- (id) init {
    self = [super init];
    if (self) {
        _repeatCount = 0;
        _speed = 1.0f;
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

        UIViewController *rvc = [[UIViewController alloc] init];
        rvc.view.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1.0];
        rvc.view.layer.cornerRadius = 16;
        rvc.view.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
        rvc.view.layer.borderWidth = 1;
        rvc.view.clipsToBounds = YES;
        _window.rootViewController = rvc;
        UIView *cv = rvc.view;

        // Header
        UILabel *ttl = [[UILabel alloc] initWithFrame:CGRectMake(12,10,pw-100,28)];
        ttl.text = @"ZXTouch"; ttl.font = [UIFont boldSystemFontOfSize:17];
        ttl.textColor = [UIColor blackColor]; [cv addSubview:ttl];

        // Settings gear button
        UIButton *gearBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [gearBtn setTitle:@"⚙️" forState:UIControlStateNormal];
        gearBtn.frame = CGRectMake(pw-80, 6, 36, 36);
        [gearBtn addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
            [self toggleSettings];
        }] forControlEvents:UIControlEventTouchUpInside];
        [cv addSubview:gearBtn];

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
        recBtn.backgroundColor = [UIColor colorWithRed:1 green:0.93 blue:0.93 alpha:1];
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

        // Settings view (hidden initially)
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(0, 54+BTN_H+4, pw, 0)];
        _settingsView.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1.0];
        _settingsView.clipsToBounds = YES;
        [cv addSubview:_settingsView];
        [self buildSettingsInView:_settingsView width:pw];

        [cv addSubview:[self makeSepAt:CGRectMake(0, 54+BTN_H+8, pw, 1)]];

        // Scripts label
        UILabel *sl = [[UILabel alloc] initWithFrame:CGRectMake(12, 54+BTN_H+14, pw-20, 18)];
        sl.text = @"Scripts"; sl.font = [UIFont boldSystemFontOfSize:12];
        sl.textColor = [UIColor grayColor]; [cv addSubview:sl];

        // Script scroll view
        CGFloat scrollTop = 54+BTN_H+36;
        _scriptScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,scrollTop,pw,ph-scrollTop-8)];
        _scriptScrollView.backgroundColor = [UIColor clearColor];
        [cv addSubview:_scriptScrollView];

        // Store dynamic refs
        _window.tag = 999;
    });
}

- (UIView*) makeSepAt:(CGRect)r {
    UIView *s = [[UIView alloc] initWithFrame:r];
    s.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    return s;
}

- (void) buildSettingsInView:(UIView*)sv width:(CGFloat)pw {
    CGFloat y = 8;

    // Repeat
    UILabel *rl = [[UILabel alloc] initWithFrame:CGRectMake(12,y,80,22)];
    rl.text = @"Repeat:"; rl.font = [UIFont systemFontOfSize:13]; rl.textColor = [UIColor darkGrayColor];
    [sv addSubview:rl];

    UIButton *rMinus = makeBtn(@"−", [UIColor systemBlueColor]);
    rMinus.frame = CGRectMake(pw-130, y, 36, 28);
    [rMinus addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        if (_repeatCount > 0) { _repeatCount--; [self updateSettingsLabels]; }
    }] forControlEvents:UIControlEventTouchUpInside];
    [sv addSubview:rMinus];

    _repeatLabel = [[UILabel alloc] initWithFrame:CGRectMake(pw-90,y,40,28)];
    _repeatLabel.textAlignment = NSTextAlignmentCenter;
    _repeatLabel.font = [UIFont systemFontOfSize:14];
    [sv addSubview:_repeatLabel];

    UIButton *rPlus = makeBtn(@"+", [UIColor systemBlueColor]);
    rPlus.frame = CGRectMake(pw-48, y, 36, 28);
    [rPlus addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
        _repeatCount++; [self updateSettingsLabels];
    }] forControlEvents:UIControlEventTouchUpInside];
    [sv addSubview:rPlus];
    y += 36;

    // Speed
    UILabel *spl = [[UILabel alloc] initWithFrame:CGRectMake(12,y,60,22)];
    spl.text = @"Speed:"; spl.font = [UIFont systemFontOfSize:13]; spl.textColor = [UIColor darkGrayColor];
    [sv addSubview:spl];

    NSArray *speeds = @[@(0.5f), @(1.0f), @(1.5f), @(2.0f)];
    NSArray *labels = @[@"0.5×", @"1×", @"1.5×", @"2×"];
    CGFloat sbtnW = (pw - 80) / 4.0f;
    for (int i = 0; i < 4; i++) {
        float spd = [speeds[i] floatValue];
        UIButton *sb = makeBtn(labels[i], [UIColor systemBlueColor]);
        sb.frame = CGRectMake(70 + i*sbtnW, y, sbtnW - 4, 28);
        [sb addAction:[UIAction actionWithTitle:@"" image:nil identifier:nil handler:^(__kindof UIAction *a) {
            _speed = spd; [self updateSettingsLabels];
        }] forControlEvents:UIControlEventTouchUpInside];
        [sv addSubview:sb];
    }
    _speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(12,y+2,60,18)];
    _speedLabel.font = [UIFont systemFontOfSize:11]; _speedLabel.textColor = [UIColor grayColor];
    [sv addSubview:_speedLabel];

    [self updateSettingsLabels];
}

- (void) updateSettingsLabels {
    _repeatLabel.text = _repeatCount == 0 ? @"1×" : [NSString stringWithFormat:@"%d×", _repeatCount+1];
    _speedLabel.text = [NSString stringWithFormat:@"%.1f×", _speed];
}

- (void) toggleSettings {
    dispatch_async(dispatch_get_main_queue(), ^{
        _settingsVisible = !_settingsVisible;
        CGFloat newH = _settingsVisible ? 80 : 0;
        [UIView animateWithDuration:0.2 animations:^{
            CGRect f = _settingsView.frame;
            f.size.height = newH;
            _settingsView.frame = f;
        }];
    });
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
        btn.backgroundColor = [UIColor whiteColor];
        btn.layer.cornerRadius = 8;
        btn.layer.borderColor = [UIColor colorWithWhite:0.88 alpha:1.0].CGColor;
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
                    // Settings mode on: ask for confirm with current settings
                    NSString *settingsInfo = [NSString stringWithFormat:
                        @"Script: %@\nRepeat: %d time(s)\nSpeed: %.1f×\n\nRun with these settings?",
                        item[@"label"], _repeatCount + 1, _speed];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Play Settings"
                        message:settingsInfo preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Run" style:UIAlertActionStyleDefault handler:^(UIAlertAction *aa) {
                        [self hide];
                        [self saveSettings:_repeatCount speed:_speed];
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
                    [self saveSettings:_repeatCount speed:_speed];
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

- (void) saveSettings:(int)repeat speed:(float)speed {
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    config[@"scriptPlaybackInfo"] = @{
        SETTINGS_KEY_REPEAT: @(repeat),
        SETTINGS_KEY_SPEED: @(speed),
        SETTINGS_KEY_INTERVAL: @(0)
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *err = nil;
        stopScriptPlaying(&err);
        if (err) showAlertBox(@"Error", [NSString stringWithFormat:@"Stop error: %@", err], 999);
        else showAlertBox(@"ZXTouch", @"Script stopped.", 1);
    });
}

- (void) show {
    [self refreshScriptList];
    [self repositionWindow];
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

- (BOOL) isShown { return isShown; }

@end
