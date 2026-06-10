#ifndef ALERT_BOX_H
#define ALERT_BOX_H

#import <Foundation/Foundation.h>

void showAlertBox(NSString* title, NSString* content, int dismissTime);
void showAlertBoxFromRawData(UInt8 *eventData, NSError **error);

#endif