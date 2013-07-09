//
//  DownloadManager.h

//
//  Created by omkar_ramtekkar on 13/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

/**
 * @class DownloadManager
 * @description DownloadManager This class manages the download operations. Proves the facility to cancel, pause and resume download operations
 * Note : By default this class implements the @protocol DownloadOperationDelegate methods.
 */

#import <Foundation/Foundation.h>
#import "DownloadOperationDelegate.h"

@class ResourceRequest;
@class Reachability;

@interface DownloadManager : NSObject<DownloadOperationDelegate>
{
@private
    NSOperationQueue *_queue;
    Reachability        *_internetConnectionReachability;
    Reachability        *_wifiConnectionReachability;
    
    NSMutableDictionary *_runningOperations; //<Dictonary of ScreenName vs Array of running DownloadOperation>[NSString, NSArray]
    NSMutableDictionary *_pausedOperations; //<Dictonary of ScreenName vs Array of paused DownloadOperation>[NSString, NSArray]
}

+(DownloadManager*) sharedInstance;
-(void) releaseInstance;

-(void) downloadResource:(ResourceRequest*) resourceRequest overriteIfExists:(BOOL) bOverrite context:(void*) context;

-(void) cancelResourceRequest:(ResourceRequest*) request context:(void*) context;
-(void) pauseResourceRequest:(ResourceRequest*) request context:(void*) context;
-(void) resumeResourceRequest:(ResourceRequest*) request context:(void*) context;

-(void) cancelAllResourceRequests:(void*) context;
-(void) pauseAllResourceRequests:(void*) context;
-(void) resumeAllResourceRequests:(void*) context;

@end
