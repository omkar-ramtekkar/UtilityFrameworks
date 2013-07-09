//
//  DownloadManager.m

//
//  Created by omkar_ramtekkar on 13/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import "DownloadManager.h"
#import "DownloadOperation.h"
#import "Resource.h"
#import "ResourceRequest.h"
#import "OfflineStorageModel.h"
#import "Reachability.h"
#import "Constants.h"
#import "NotificationHelper.h"

static DownloadManager* downloadManager_g = nil;


NSString* GetDownloadDirPath()
{
    static NSString *downloadDirPath_g = nil;
    if (downloadDirPath_g)
    {
        return downloadDirPath_g;
    }
    else
    {
        //Offline Dir Path
        NSString *libraryDirPath = [[[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject] path];
        downloadDirPath_g = [[libraryDirPath stringByAppendingPathComponent:@"Downloads"] retain];
    }
    return downloadDirPath_g;
}


@interface DownloadManager()

-(void) initialize;
-(void) registerNotifications;
-(void) unregisterNotifications;

-(void) viewWillAppearHandler:(NSNotification*) notification;
-(void) viewDidDisappearHandler:(NSNotification*) notification;

@end


@implementation DownloadManager

+(DownloadManager*) sharedInstance
{
    if (downloadManager_g)
    {
        return downloadManager_g;
    }
    else
    {
        static dispatch_once_t pred;
        dispatch_once(&pred,^{
            downloadManager_g = [[DownloadManager alloc] init];
            assert(downloadManager_g);
            [downloadManager_g initialize];
        });
        
        return downloadManager_g;
    }
}

-(void) initialize
{
    [self releaseInstance];
    
    _queue = [[NSOperationQueue alloc] init];
    [_queue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    [_queue setName:@"ResourceDownloadQueue"];
    
    _runningOperations = [[NSMutableDictionary alloc] init];
    _pausedOperations = [[NSMutableDictionary alloc] init];
    
    _internetConnectionReachability = [[Reachability reachabilityForInternetConnection] retain];
    _wifiConnectionReachability = [[Reachability reachabilityForLocalWiFi] retain];
    
    [self registerNotifications];
}


-(void) releaseInstance
{
    [_queue release];
    [_runningOperations release];
    [_pausedOperations release];
    [_internetConnectionReachability release];
    [_wifiConnectionReachability release];
    
    [self unregisterNotifications];
}

-(void) registerNotifications
{
    [self unregisterNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillAppearHandler:) name:kNotificationViewWillAppear object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidDisappearHandler:) name:kNotificationViewDidDisappear object:nil];
}


-(void) unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void) viewWillAppearHandler:(NSNotification*) notification
{
    NSString *screenName = [[notification userInfo] objectForKey:kScreenName];
    assert(screenName);
    [self resumeAllResourceRequests:screenName];
}


-(void) viewDidDisappearHandler:(NSNotification*) notification
{
    NSString *screenName = [[notification userInfo] objectForKey:kScreenName];
    assert(screenName);
    
    [self pauseAllResourceRequests:screenName];
}

-(void) downloadResource:(ResourceRequest*) resourceRequest overriteIfExists:(BOOL) bOverrite context:(void*) context
{
    NSString *screenName = (NSString*) context;
    assert(screenName);
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    BOOL bAvailable = [[OfflineStorageModel sharedInstance] isResourceAvailable:resourceRequest.resource];
    BOOL bValidResource = [[OfflineStorageModel sharedInstance] isValidResource:resourceRequest.resource];
    BOOL bDownload = NO;
    
    if ((bOverrite && bAvailable) || !bValidResource)
    {
        //Delete Resource and download
        [[OfflineStorageModel sharedInstance] deleteResource:resourceRequest.resource];
        bDownload = YES;
    }
    else if(bAvailable && bValidResource)
    {
        //Return existing resource
        if ([resourceRequest.delegate respondsToSelector:@selector(downloadDidFinish:)])
        {
            [resourceRequest.delegate downloadDidFinish:nil];
        }
    }
    else
    {
        //Download Resource
        bDownload = YES;
    }
    
    if (bDownload && (([_internetConnectionReachability currentReachabilityStatus] != NotReachable) ||
                      ([_wifiConnectionReachability currentReachabilityStatus] != NotReachable)) )
    {
        //Check for existing download operation going for same resource
        DownloadOperation *newOperation = [[DownloadOperation alloc] initWithRequest:resourceRequest];
        newOperation.supportPauseResume = resourceRequest.supportPauseResume;
        
        NSArray *queuedOperations = [_queue operations];
        
        DownloadOperation *queuedOperation = nil;
        NSUInteger index = [queuedOperations indexOfObject:newOperation];
        if (index != NSNotFound)
        {
            queuedOperation = [queuedOperations objectAtIndex:index];
        }
        
        //If we have an existing operation in queue then just add the delegate, if not then add it to operation queue.
        if(queuedOperation)
        {
            [queuedOperation addDelegate:resourceRequest.delegate];
        }
        else
        {
            //Now check if the operation is in paused operatinos
            NSArray *pausedOperations = [_pausedOperations objectForKey:screenName];
            DownloadOperation *pausedOperation = nil;
            index = [pausedOperations indexOfObject:newOperation];
            if (index != NSNotFound)
            {
                pausedOperation = [pausedOperations objectAtIndex:index];
            }
            
            if (pausedOperation)
            {
                //Now we need to resume the paused operation, before that get all delegates of paused operation and
                //update the newOperation delegates.
                NSSet *delegates = pausedOperation.delegates;
                for (id delegate in delegates)
                {
                    [newOperation addDelegate:delegate];
                }
            }
            
            //CAUTION! : Do not remove pausedOperation from pausedOperations here, it will be removed while observing the keypaths
            
            [newOperation addObserver:self forKeyPath:@"isFinished" options:0 context:context];
            [newOperation addObserver:self forKeyPath:@"isPaused" options:0 context:context];
            [newOperation addObserver:self forKeyPath:@"isExecuting" options:0 context:context];
            @synchronized(_queue)
            {
                [_queue addOperation:newOperation];
            }
        }
        
        [newOperation release];
    }
    
    [pool drain];
}

-(void) cancelResourceRequest:(ResourceRequest*) request context:(void*) context
{
    NSString *screenName = (NSString*) context;
    assert(screenName);
    
    @synchronized(_runningOperations)
    {
        DownloadOperation *op = [[DownloadOperation alloc] initWithRequest:request];
        NSMutableArray *runningOperations = [_runningOperations objectForKey:screenName];
        
        NSOperation *operationToCancel = nil;
        
        for (NSOperation *operation in runningOperations)
        {
            if ([operation isEqual:op])
            {
                operationToCancel = operation;
                break;
            }
        }
        
        if (operationToCancel)
        {
            [operationToCancel cancel];
        }
        
        [op release];
    }
}

-(void) pauseResourceRequest:(ResourceRequest*) request context:(void*) context
{
    NSString *screenName = (NSString*) context;
    assert(screenName);
    assert(request.supportPauseResume);//Request should support pause-resume
    
    @synchronized(_runningOperations)
    {
        DownloadOperation *op = [[DownloadOperation alloc] initWithRequest:request];
        NSMutableArray *runningOperations = [_runningOperations objectForKey:screenName];
        DownloadOperation *operationToPause = nil;
        
        for (DownloadOperation *operation in runningOperations)
        {
            if ([operation isEqual:op])
            {
                operationToPause = operation;
                break;
            }
        }
        
        if (operationToPause)
        {
            [operationToPause pause];
        }
        
        [op release];
    }
}

-(void) resumeResourceRequest:(ResourceRequest*) request context:(void*) context
{
    NSString *screenName = (NSString*) context;
    assert(screenName);
    
    assert(request.supportPauseResume);//Request should support pause-resume
    
    @synchronized(_pausedOperations)
    {
        DownloadOperation *op = [[DownloadOperation alloc] initWithRequest:request];
        NSMutableArray *pausedOperations = [_pausedOperations objectForKey:screenName];
        
        DownloadOperation *operationToResume = nil;
        
        for (DownloadOperation *operation in pausedOperations)
        {
            if ([operation isEqual:op])
            {
                operationToResume = operation;
                break;
            }
        }
        
        if (operationToResume)
        {
            [self downloadResource:operationToResume.request overriteIfExists:NO context:context];
        }
        
        [op release];
    }
}

-(void) cancelAllResourceRequests:(void*) context
{
    NSString *screenName = (NSString*) context;
    assert(screenName);
    
    @synchronized(_runningOperations)
    {
        NSMutableArray* runningOperations = [_runningOperations objectForKey:screenName];
        
        //PRECAUTION : Use temporary array for iterating operations, since [operation cancel] will cause other flow which
        //may cause _runningOperations to modify.
        NSMutableArray *tempArrayStore = [NSMutableArray arrayWithArray:runningOperations];
        
        for (NSOperation *operation in tempArrayStore)
        {
            [operation cancel];
        }
    }
}

-(void) pauseAllResourceRequests:(void*) context
{
    NSString *screenName = (NSString*) context;
    assert(screenName);
    
    @synchronized(_runningOperations)
    {
        NSMutableArray *runningOperations = [_runningOperations objectForKey:screenName];
        //PRECAUTION : Use temporary array for iterating operations, since [operation pause] will cause other flow which
        //may cause _runningOperations to modify.
        
        NSMutableArray *tempArrayStore = [NSMutableArray arrayWithArray:runningOperations];
        for (DownloadOperation *operation in tempArrayStore)
        {
            [operation pause];
        }
    }
}

-(void) resumeAllResourceRequests:(void*) context
{
    NSString *screenName = (NSString*) context;
    assert(screenName);
    
    @synchronized(_pausedOperations)
    {
        NSMutableArray *pausedOperations = [_pausedOperations objectForKey:screenName];
        //PRECAUTION : Use temporary array for iterating operations, since [_queue addOperation:operation] will cause other flow which
        //may cause _pausedOperations to modify.
        NSMutableArray *tempArrayStore = [NSMutableArray arrayWithArray:pausedOperations];
        
        for (DownloadOperation *operation in tempArrayStore)
        {
            [self downloadResource:operation.request overriteIfExists:NO context:context];
        }
    }
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    @synchronized(self)
    {
        NSString *screenName = (NSString*) context;
        DownloadOperation *operation = (DownloadOperation*) object;
        
        assert(screenName);
        assert(operation);
        
        if ([keyPath isEqualToString:@"isFinished"])
        {
            //If DownloadOperation changes its state to finished then remove it from runningOperations array
            assert(operation);
            if (operation)
            {
                if(operation.isFinished && !operation.isCancelled && !operation.isPaused)
                {
                    [self downloadDidFinish:object];
                    [operation removeObserver:self forKeyPath:@"isFinished" context:context];
                    [operation removeObserver:self forKeyPath:@"isPaused" context:context];
                    [operation removeObserver:self forKeyPath:@"isExecuting" context:context];
                    
                    NSMutableArray *runningOperations = [_runningOperations objectForKey:screenName];
                    [runningOperations removeObject:operation];
                }
            }
        }
        else if([keyPath isEqualToString:@"isPaused"])
        {
            //If DownloadOperation changes its state to paused then add it to pausedOperations array
            //Note : Paused is a two state operation
            //1. calcel the execution
            //2. Mark the operation status as paused
            //So do not remove it from runningOperatinos array here, it will be taken care by above if
            NSMutableArray *pausedOperations = [_pausedOperations objectForKey:screenName];
            
            if(operation.isPaused)
            {
                if (!pausedOperations)
                {
                    pausedOperations = [NSMutableArray array];
                    [_pausedOperations setObject:pausedOperations forKey:screenName];
                }
                
                [pausedOperations addObject:operation];
            }
            else
            {
                [pausedOperations removeObject:operation];
            }
        }
        else if([keyPath isEqualToString:@"isExecuting"])
        {
            NSMutableArray *runningOperations = [_runningOperations objectForKey:screenName];
            
            if(operation.isExecuting)
            {
                if(!runningOperations)
                {
                    runningOperations = [NSMutableArray array];
                    [_runningOperations setObject:runningOperations forKey:screenName];
                }
                [runningOperations addObject:operation];
                
                NSMutableArray *pausedOperations = [_pausedOperations objectForKey:screenName];
                [pausedOperations removeObject:operation];
            }
            else
            {
                [runningOperations removeObject:operation];
            }
            
        }
    }
    
    //Dissolve the keyvalue  change here
    //Note: Do not pass it to super class, otherwise it will throw an exception
}

-(void) downloadDidFinish:(DownloadOperation*) operation
{
    if (operation)
    {
        NSNotification* notification = [NSNotification notificationWithName:kNotificationResourceDownloaded object:operation];
        [NotificationHelper postNotification:notification];
    }
}


-(void) dealloc
{
    [_queue cancelAllOperations];//Cancel all operations before killing the app
    [_queue release];
    
    [_runningOperations removeAllObjects];
    [_runningOperations release];
    
    [_pausedOperations removeAllObjects];
    [_pausedOperations release];
        
    _queue = nil;
    _runningOperations = nil;
    _pausedOperations = nil;
    
    [super dealloc];
}

@end
