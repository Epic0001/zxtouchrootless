#include "Play.h"
#include "SocketServer.h"
#include "Process.h"
#include "Task.h"
#include "AlertBox.h"
#include "Config.h"
#import "ScriptPlayer.h"
#include "Common.h"

static BOOL switchAppBeforeRunScript = true;
ScriptPlayer *scriptPlayer;

void initScriptPlayer()
{
    scriptPlayer = [[ScriptPlayer alloc] init];
}

void updateSwtichAppBeforeRunScript(BOOL value)
{
    switchAppBeforeRunScript = value;
}

int playScript(UInt8* path, NSError **error)
{
    if (!scriptPlayer)
    {
        NSLog(@"com.zjx.springboard: Unable to run the script. Internal error. scriptPlayer is null.");
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Unable to run the script. Internal error. scriptPlayer is null.\r\n"}];
        return -1;
    }
    // read config file to get repeat time etc
    int repeatTime = 0;
    float sleepBetweenRun = 0;
    float playSpeed = 1.0f;
    
    NSLog(@"com.zjx.springboard: path: %s", path);
    NSDictionary *config = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:SCRIPT_PLAY_CONFIG_PATH])
        config = [[NSDictionary alloc] initWithContentsOfFile:SCRIPT_PLAY_CONFIG_PATH];

    if (config)
    {
        // Per-script settings (written by ZXTouch app) take priority
        NSDictionary *individualConfigs = config[@"individual_configs"];
        NSDictionary *scriptInfo = [individualConfigs valueForKey:[NSString stringWithFormat:@"%s", path]];

        // Fall back to global settings written by the panel
        if (!scriptInfo)
            scriptInfo = config[@"scriptPlaybackInfo"];

        if (scriptInfo)
        {
            repeatTime = [scriptInfo[@"repeat_times"] intValue];
            sleepBetweenRun = [scriptInfo[@"interval"] floatValue];
            float sp = [scriptInfo[@"speed"] floatValue];
            if (sp > 0) playSpeed = sp;
        }
    }
    

    [scriptPlayer setPath:[NSString stringWithFormat:@"%s", path]];
    [scriptPlayer setRepeatTime:repeatTime];
    [scriptPlayer setSpeed:playSpeed];
    [scriptPlayer setInterval:sleepBetweenRun];
    [scriptPlayer setSwitchApp:switchAppBeforeRunScript];

    [scriptPlayer play:error];

    return 0;
}


void stopScriptPlaying(NSError **error)
{
    [scriptPlayer forceStop:error];
}

BOOL isScriptPlaying()
{
    return scriptPlayer && [scriptPlayer isPlaying];
}

void playHasStoppedCallBack()
{
    NSString *bundlePath = [scriptPlayer getCurrentBundlePath];
    NSString *scriptName = (bundlePath.length > 0) ? [[bundlePath lastPathComponent] stringByDeletingPathExtension] : @"Unknown";
    int completedRuns = [scriptPlayer getCompletedRuns];

    NSDictionary *settings = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:SCRIPT_PLAY_CONFIG_PATH])
        settings = [[NSDictionary alloc] initWithContentsOfFile:SCRIPT_PLAY_CONFIG_PATH];
    NSDictionary *info = settings[@"scriptPlaybackInfo"];
    float speed = info[@"speed"] ? [info[@"speed"] floatValue] : 1.0f;

    NSString *msg = [NSString stringWithFormat:@"Script: %@\nSpeed: %.1f×\nPlayed: %d time(s)",
                     scriptName, speed, completedRuns];
    showAlertBox(@"Script Finished", msg, 2);
}