#include "UIKeyboard.h"
#import <UIKit/UIKit.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#define TASK_GET_TEXT_FROM_CLIPBOARD 6
#define TASK_SAVE_TEXT_TO_CLIPBOARD 7

NSString* inputTextFromRawData(UInt8 *eventData, NSError **error)
{
    NSArray *data = [[NSString stringWithUTF8String:(char*)eventData] componentsSeparatedByString:@";;"];

    NSString *taskContent = @"";
    if ([data count] < 1)
    {
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Keyboard related event length error. You have to specify the task id.\r\n"}];
        return nil;
    }
    int taskType = [data[0] intValue];
    if (taskType == TASK_GET_TEXT_FROM_CLIPBOARD)
    {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];

        if (!pasteboard.string)
            return @"";

        return pasteboard.string;
    }
    else if (taskType == TASK_SAVE_TEXT_TO_CLIPBOARD)
    {  
        if ([data count] < 2)
        {
            *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Keyboard related event error. You have to specify the content you want to paste to clipboard.\r\n"}];
            return nil;
        }
        
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        pb.string = data[1];
        return @"";
    }

    // Text injection via appdelegate tweak is not supported in this rootless build.
    // The appdelegate tweak has been removed due to iOS 16 incompatibility.
    *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999
        userInfo:@{NSLocalizedDescriptionKey:@"-1;;Text input (insert_text/key_press) is not supported in this build. Use clipboard paste as an alternative.\r\n"}];
    return nil;

}