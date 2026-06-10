#ifndef PROCESS_H
#define PROCESS_H

#import <Foundation/Foundation.h>
#include <dlfcn.h>

int switchProcessForegroundFromRawData(UInt8 *eventData);
int bringAppForeground(NSString *appIdentifier);
id getFrontMostApplication();

#endif