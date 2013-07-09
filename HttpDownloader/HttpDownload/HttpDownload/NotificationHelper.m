//
//  NotificationHelper.m
//  HttpDownload
//
//  Created by omkar_ramtekkar on 19/06/13.
//  Copyright (c) 2013 omkar_ramtekkar. All rights reserved.
//

#import "NotificationHelper.h"

@implementation NotificationHelper

+(void) postNotificationWithName:(NSString*) notificationName
{
    NSNotification *notification = [NSNotification notificationWithName:notificationName object:nil];
    [NotificationHelper postNotification:notification];
}

+(void) postNotification:(NSNotification*) notification
{
    [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

@end
