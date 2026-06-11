#ifndef RECORD_H
#define RECORD_H

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wavailability"
#pragma clang diagnostic ignored "-Wattributes"
#include "headers/IOHIDEvent.h"
#include "headers/IOHIDEventData.h"
#include "headers/IOHIDEventTypes.h"
#include "headers/IOHIDEventSystemClient.h"
#include "headers/IOHIDEventSystem.h"
#pragma clang diagnostic pop

#include <mach/mach_time.h>

void startRecording(CFWriteStreamRef requestClient, NSError **error);
void stopRecording();
static void recordIOHIDEventCallback(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event);
Boolean isRecordingStart();

#endif