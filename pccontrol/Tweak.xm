#include "headers/BKUserEventTimer.h"
#import <QuartzCore/QuartzCore.h>

#include <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <sys/sysctl.h>
#include <sys/xattr.h>
#include <substrate.h>
#include <math.h>

#include <mach/mach.h>
#import <CoreGraphics/CoreGraphics.h>
#import <IOKit/hid/IOHIDService.h>

#include<mach-o/dyld.h>

#include <stdlib.h>
#include "socketConfig.h"

#include <stdio.h>
#include <unistd.h>
#include <signal.h>

#include <notify.h>
#include "headers/CFUserNotification.h"
#import <os/lock.h>

#include "Touch.h"
#include "SocketServer.h"
#include "Common.h"
#include "Screen.h"
#include "AlertBox.h"
#include "Popup.h"
#include "Record.h"
#include "Toast.h"
#include "Play.h"
#include "TouchIndicator/TouchIndicatorWindow.h"
#include <rootless.h>

#define IPHONE7P_HEIGHT 1920
#define IPHONE7P_WIDTH 1080

#define IPADPRO_HEIGHT 2732
#define IPADPRO_WIDTH 2048

#define SET_SIZE 9




int daemonSock = -1;


typedef struct　eventInfo_s* eventInfo;
typedef struct Node* llNodePtr;
typedef struct eventData_s* eventDataPtr;


const int TOUCH_EVENT_ARR_LEN = 20;

Boolean isCrazyTapping = false;
Boolean isRecording = false;



const NSString *recordingScriptName = @"rec";


eventInfo touchEventArr[TOUCH_EVENT_ARR_LEN] = {0};


llNodePtr eventLinkedListHead = NULL;


Boolean isInitializedSuccess = true;

int getDaemonSocket();
void *(*IOHIDEventAppendEventOld)(IOHIDEventRef parent, IOHIDEventRef child);


float getRandomNumberFloat(float min, float max);

int getTaskType(UInt8* dataArray);

void handle_event (void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event);




void setSenderIdCallback(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event);

static void stopCrazyTapCallback();
void crazyTapTimeUpCallback();
void stopCrazyTap();
void processTask(UInt8 *buff);

void updateSwtichAppBeforeRunScript(BOOL value);
BOOL openPopUpByDoubleVolumnDown = true;

// -------------
IOHIDEventSystemClientRef ioHIDEventSystemForPopupDectect = NULL;
PopupWindow *popupWindow;


void stopCrazyTap()
{
    isCrazyTapping = false;
}




/*
A callback to stop crazy tap.

Note: using a callback to stop crazy tap is because the socket server may not respond while crazy tapping
*/
static void stopCrazyTapCallback()
{
    stopCrazyTap();
}


void crazyTapTimeUpCallback(int sig)
{
    NSLog(@"com.zjx.springboard: crazy tap stop.");
    stopCrazyTap();
}

void dontPutThisFileIntoIda()
{
    return;
}

void becauseTheSourceCodeWillBeReleasedAtGithub()
{
    return;
}

void repoNameIsIOS13SimulateTouch()
{
    return;
}

/*
Get the sender id and unregister itself.
*/
static CFTimeInterval startTime = 0;
// perform some action
static void popupWindowCallBack(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event)
{
    if (!openPopUpByDoubleVolumnDown)
        return;
    if (IOHIDEventGetType(event) == kIOHIDEventTypeKeyboard)
    {
        if (IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardUsage) == 234 && IOHIDEventGetIntegerValue(event, kIOHIDEventFieldKeyboardDown) == 0)
        {
            CFTimeInterval currentTime = CACurrentMediaTime();
            if (currentTime - startTime > 0.4)
            {
                startTime = CACurrentMediaTime();
                return;
            }

            if (isRecordingStart())
            {
                stopRecording();
                showAlertBox(@"Recording stopped", [NSString stringWithFormat:@"Your touch record has been saved. Please open zxtouch app to see your script list. This record script is located at %@recording", getScriptsFolder()], 999);
                [popupWindow show];
                return;
            }
            if (![popupWindow isShown])
            {
                [popupWindow show];
            }
            else
            {
                [popupWindow hide];
            }
        }
    }
}

/**
Start the callback for setting sender id
*/
void startPopupListeningCallBack()
{
    ioHIDEventSystemForPopupDectect = IOHIDEventSystemClientCreate(kCFAllocatorDefault);

    IOHIDEventSystemClientScheduleWithRunLoop(ioHIDEventSystemForPopupDectect, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDEventSystemClientRegisterEventCallback(ioHIDEventSystemForPopupDectect, (IOHIDEventSystemClientEventCallback)popupWindowCallBack, NULL, NULL);
    //NSLog(@"### com.zjx.springboard: screen width: %f, screen height: %f", device_screen_width, device_screen_height);
}


Boolean initConfig()
{
    // read config file
    // check whether config file exist
    NSString *configFilePath = getCommonConfigFilePath();

    if (![[NSFileManager defaultManager] fileExistsAtPath:configFilePath]) // if missing, then use the default value
    {
        //showAlertBox(@"Error", configFilePath, 999);
        NSLog(@"com.zjx.springboard: unable to get config file. File not found. Using default value. Path: %@", configFilePath);
        return true;
    }
    // read indicator color from the config file
    NSDictionary *config = [[NSDictionary alloc] initWithContentsOfFile:configFilePath];
    if ([config[@"touch_indicator"][@"show"] boolValue])
    {
        NSError *err = nil;
        startTouchIndicator(&err);
        if (err)
        {
            showAlertBox(@"Error", [NSString stringWithFormat:@"Cannot start touch indicator, error info: %@", err], 999);
        }
    }

    if (config[@"double_click_volume_show_popup"])
    {
        NSLog(@"com.zjx.springboard: show popup %d", [config[@"double_click_volume_show_popup"] boolValue]);
        openPopUpByDoubleVolumnDown = [config[@"double_click_volume_show_popup"] boolValue];
    }

    if (config[@"switch_app_before_run_script"])
    {
        updateSwtichAppBeforeRunScript([config[@"switch_app_before_run_script"] boolValue]);
    }

    return true;
}

Boolean init()
{
    initScriptPlayer();
    initConfig();

    return true;
}

static void zxtouch_springboard_ready(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [@"1-block-started" writeToFile:@"/var/mobile/d1.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

            CGFloat screen_scale = [[UIScreen mainScreen] scale];
            CGFloat width = [UIScreen mainScreen].bounds.size.width * screen_scale;
            CGFloat height = [UIScreen mainScreen].bounds.size.height * screen_scale;
            [Screen setScreenSize:(width<height?width:height) height:(width>height?width:height)];
            [@"3-screen-set" writeToFile:@"/var/mobile/d3.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

            popupWindow = [[PopupWindow alloc] init];
            [@"4-popup-init" writeToFile:@"/var/mobile/d4.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

            initSenderId();
            startPopupListeningCallBack();
            initTouchGetScreenSize();
            [@"5-sender-init" writeToFile:@"/var/mobile/d5.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

            if (!init()) { return; }
            [@"6-init-done" writeToFile:@"/var/mobile/d6.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

            call_system("chown -R mobile:mobile /var/mobile/Library/ZXTouch");
            [@"7-before-socketServer" writeToFile:@"/var/mobile/d7.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

            socketServer();
        });
    });
}

%ctor{
    // Only run in SpringBoard
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"SpringBoard"]) return;

    %init; // MUST call %init to register all Logos hooks when using a custom %ctor

    [@"ctor-ran" writeToFile:@"/var/mobile/d0_ctor.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];

    // Use notify_register_dispatch — GCD-based, no CFRunLoop dependency
    int token;
    notify_register_dispatch("com.apple.springboard.hasBecomeActive", &token,
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^(int t) {
            notify_cancel(t);
            [@"notif-fired" writeToFile:@"/var/mobile/d0_notif.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            zxtouch_springboard_ready(NULL, NULL, NULL, NULL, NULL);
        });

    // Fallback: if notification never fires, init after 6 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC),
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
        ^{
            [@"fallback-fired" writeToFile:@"/var/mobile/d0_fallback.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            zxtouch_springboard_ready(NULL, NULL, NULL, NULL, NULL);
        });
}

// SpringBoard hook removed - applicationDidFinishLaunching:%orig crashes SpringBoard on iOS 16
// Init is handled via %ctor + dispatch_after + Darwin notification above