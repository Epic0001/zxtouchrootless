#include "UIKeyboard.h"
#import <UIKit/UIKit.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#define TASK_GET_TEXT_FROM_CLIPBOARD 6
#define TASK_SAVE_TEXT_TO_CLIPBOARD 7

NSString* inputTextFromRawData(UInt8 *eventData, NSError **error)
{
    NSArray *data = [[NSString stringWithUTF8String:(char*)eventData] componentsSeparatedByString:@";;"];

    if ([data count] < 1)
    {
        *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Keyboard related event length error. You have to specify the task id.\r\n"}];
        return nil;
    }

    int taskType = [data[0] intValue];

    if (taskType == TASK_GET_TEXT_FROM_CLIPBOARD)
    {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        return pasteboard.string ?: @"";
    }
    else if (taskType == TASK_SAVE_TEXT_TO_CLIPBOARD)
    {
        if ([data count] < 2)
        {
            *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Keyboard related event error. You have to specify the content you want to paste to clipboard.\r\n"}];
            return nil;
        }
        [UIPasteboard generalPasteboard].string = data[1];
        return @"";
    }

    // Forward to appdelegate tweak injected in the frontmost app.
    // deliverImmediately:NO (async) — avoids the SpringBoard crash from synchronous delivery.
    NSString *taskContent = ([data count] >= 2) ? data[1] : @"";
    [[NSDistributedNotificationCenter defaultCenter]
        postNotificationName:@"com.zjx.zxtouch.keyboardcontrol"
        object:nil
        userInfo:@{@"task_id": data[0], @"task_content": taskContent}
        deliverImmediately:NO];

    return @"";
}
