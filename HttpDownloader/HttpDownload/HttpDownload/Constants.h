//
//  HttpDownload.h
//  HttpDownload
//
//  Created by omkar_ramtekkar on 19/06/13.
//  Copyright (c) 2013 omkar_ramtekkar. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNotificationViewWillAppear                         @"kNotificationViewWillAppear"
#define kNotificationViewDidDisappear                       @"kNotificationViewDidDisappear"
#define kScreenName                                         @"ScreenName"
#define kNotificationResourceDownloaded                     @"kNotificationResourceDownloaded"

#pragma mark --------------- Utitility Constants ---------------
#define kOfflineStorageLimit                100 //100 MB
#define kOfflineStorageDefaultSize          50  //50 MB
#define kDownloadUpdateNotificationDelta    25  //Send update notification after each 25% download
