//
//  DownloadOperation.h

//
//  Created by omkar_ramtekkar on 16/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

/**
 * @class DownloadOperation
 * @description This class re-presents an download operation. Maintains the execution state and progress for download operation 
 * Note : Developer can create an object of DownloadOperation, but it's recommended not to create it, use @class DownloadManager class 
 * to download any resource
 */
#import <Foundation/Foundation.h>

@class ResourceRequest;

@interface DownloadOperation : NSOperation
{
@protected
    BOOL            _bFinished;
    BOOL            _bExecuting;
    BOOL            _bIsConcurrent;
    BOOL            _bPaused;
    NSUInteger      _progress;
    
    NSMutableSet    *_delegates;
    
    NSMutableData   *_responseData;
    NSURLConnection *_urlConnection;
    ResourceRequest *_resourceRequest;
    NSUInteger       _expectedContentLength;
    NSFileHandle    *_temporaryFile;
    NSString        *_partialDownloadFile;
}

@property(nonatomic, assign)    BOOL        concurrent;
@property(assign, nonatomic)    BOOL        supportPauseResume;
@property(readonly, nonatomic)  BOOL        isPaused;
@property(readonly, assign)     NSUInteger  progress;
@property(readonly, nonatomic)  NSData      *responseData;
@property(readonly, nonatomic)  NSString    *partialDownloadFile;
@property(readonly, nonatomic)  NSSet       *delegates;
@property(readonly, nonatomic)  ResourceRequest *request;


-(id) initWithRequest:(ResourceRequest*) request;
+(DownloadOperation*) operationWithDownloadOperation:(DownloadOperation*) operation;
-(void) addDelegate:(id) delegate;
-(BOOL) pause;

@end
