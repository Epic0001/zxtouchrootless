#include "UpdateCache.h"
#include "Common.h"
#include "Popup.h"

#define UPDATE_POPUP_WINDOW_VOLUMN_DOWN_OPEN_FROM_CONFIG 1
#define UPDATE_SWITCH_APP_BEFORE_RUN_SCRIPT 2
#define UPDATE_DARK_MODE 3

void updateSwtichAppBeforeRunScript(BOOL value);
void applyPanelDarkMode(BOOL dark);

extern BOOL openPopUpByDoubleVolumnDown;

void updateCacheFromRawData(UInt8* eventData, NSError **error)
{
    NSArray *data = [[NSString stringWithFormat:@"%s", eventData] componentsSeparatedByString:@";;"];

    int type = [data[0] intValue];

    if (type == UPDATE_POPUP_WINDOW_VOLUMN_DOWN_OPEN_FROM_CONFIG)
    {
        NSString *configFilePath = getCommonConfigFilePath();

        NSDictionary *config = [[NSDictionary alloc] initWithContentsOfFile:configFilePath];

        if (config[@"double_click_volume_show_popup"])
        {
            openPopUpByDoubleVolumnDown = [config[@"double_click_volume_show_popup"] boolValue];
        }
    }
    if (type == UPDATE_SWITCH_APP_BEFORE_RUN_SCRIPT)
    {
        NSString *configFilePath = getCommonConfigFilePath();
        NSDictionary *config = [[NSDictionary alloc] initWithContentsOfFile:configFilePath];
        if (config[@"switch_app_before_run_script"])
        {
            updateSwtichAppBeforeRunScript([config[@"switch_app_before_run_script"] boolValue]);
        }
    }
    if (type == UPDATE_DARK_MODE)
    {
        NSString *configFilePath = getCommonConfigFilePath();
        NSDictionary *config = [[NSDictionary alloc] initWithContentsOfFile:configFilePath];
        BOOL dark = config[@"dark_mode"] ? [config[@"dark_mode"] boolValue] : NO;
        applyPanelDarkMode(dark);
    }
    else
    {
        NSLog(@"com.zjx.springboard: unknown task type for updating cache.");
    }
}