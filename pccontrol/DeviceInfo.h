#ifndef DEVICE_INFO_H
#define DEVICE_INFO_H

#import <Foundation/Foundation.h>

#define DEVICE_INFO_TASK_GET_SCREEN_SIZE 1
#define DEVICE_INFO_TASK_GET_SCREEN_ORIENTATION 2
#define DEVICE_INFO_TASK_GET_SCREEN_SCALE 3

// 1-30 reserved for screen

#define DEVICE_INFO_TASK_GET_DEVICE_INFO 30
#define DEVICE_INFO_TASK_GET_BATTERY_INFO 31

NSString *getDeviceInfoFromRawData(UInt8* eventData, NSError **error);

#endif
