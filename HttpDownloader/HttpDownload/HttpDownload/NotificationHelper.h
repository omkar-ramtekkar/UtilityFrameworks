//
//  NotificationHelper.h
//  HttpDownload
//
//  Created by omkar_ramtekkar on 19/06/13.
//  Copyright (c) 2013 omkar_ramtekkar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationHelper : NSObject

+(void) postNotificationWithName:(NSString*) notificationName;
+(void) postNotification:(NSNotification*) notification;

@end
