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
#include "RootlessPath.h"

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

%ctor{
    [@"pccontrol loaded" writeToFile:@"/var/mobile/pccontrol_ctor.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

%hook SpringBoard
#define CGRectSetPos( r, x, y ) CGRectMake( x, y, r.size.width, r.size.height )

- (void)applicationDidFinishLaunching:(id)arg1
{
    [@"applicationDidFinishLaunching fired" writeToFile:@"/var/mobile/pccontrol_hook.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    %orig;
    [@"after orig before dispatch" writeToFile:@"/var/mobile/pccontrol_before_dispatch.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [@"dispatch block started" writeToFile:@"/var/mobile/pccontrol_dispatch.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        CGFloat screen_scale = [[UIScreen mainScreen] scale];

        CGFloat width = [UIScreen mainScreen].bounds.size.width * screen_scale;
        CGFloat height = [UIScreen mainScreen].bounds.size.height * screen_scale;

        [Screen setScreenSize:(width<height?width:height) height:(width>height?width:height)];    

        //CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)stopCrazyTapCallback, CFSTR("com.zjx.crazytap.stop"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        popupWindow = [[PopupWindow alloc] init];

        initSenderId();
        startPopupListeningCallBack();

        // init touch screensize. Temporarily put this line here. Will be removed.
        initTouchGetScreenSize();

        // init other things
        if (!init())
        {
            return;
        }

     /*
        
        // Add a handler to respond to GET requests on any URL
        [_webServer addDefaultHandlerForMethod:@"GET"
                                requestClass:[GCDWebServerRequest class]
                                processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        
        return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
        
        }];
        */
        
        // Start server on port 8080
        //[_webServer startWithPort:8080 bonjourName:nil];
        //NSLog(@"com.zjx.springboard: Visit %@ in your web browser", _webServer.serverURL);

        call_system("chown -R mobile:mobile /var/mobile/Library/ZXTouch");

        socketServer();
    });
}
%end