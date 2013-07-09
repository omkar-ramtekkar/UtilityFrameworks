//
//  DownloadOperation.m

//
//  Created by omkar_ramtekkar on 16/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import "DownloadOperation.h"
#import "ResourceRequest.h"
#import "Resource.h"
#import "DownloadOperationDelegate.h"
#import "DownloadManager.h"
#import "Globals.h"


static inline NSString * GetContentTypeForPathExtension(NSString *extension)
{
#ifdef __UTTYPE__
    CFStringRef cfUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
    CFStringRef cfContentType = UTTypeCopyPreferredTagWithClass(cfUTI, kUTTagClassMIMEType);
    CFRelease(cfUTI);
    NSString *nsContentType = (NSString*)cfContentType;
    if (!nsContentType) {
        return @"audio/mpeg3;audio/x-mpeg-3;video/mpeg;video/x-mpeg;text/xml;application/octet-stream";
    } else {
        return [nsContentType autorelease];
    }
#else
    return @"audio/mpeg3;audio/x-mpeg-3;video/mpeg;video/x-mpeg;text/xml;application/octet-stream";
#endif
}

@interface DownloadOperation()

-(BOOL) isPartialDownloadFileAvailableForURL:(NSURL*) url;
-(NSFileHandle*) createTemporaryDownloadFileForURL:(NSURL*) url;
-(void) deleteTemporaryDownloadFileForURL:(NSString*) partialDownloadFile;
-(void) done;
-(void) restart;
@end

@implementation DownloadOperation

@dynamic  responseData;
@synthesize progress = _progress;
@synthesize concurrent = _bIsConcurrent;
@synthesize request = _resourceRequest;
@synthesize supportPauseResume = _supportPauseResume;
@synthesize partialDownloadFile = _partialDownloadFile;
@synthesize isPaused = _bPaused;
@synthesize delegates = _delegates;


-(id) initWithRequest:(ResourceRequest*) request
{
    if (self = [super init])
    {
        _responseData = nil;
        _bFinished = NO;
        _bExecuting = NO;
        _bIsConcurrent = YES;
        _resourceRequest = [request copy];
        _urlConnection = nil;
        _progress = 0;
        _expectedContentLength = 0;
        _supportPauseResume = NO;
        _partialDownloadFile = nil;
        _delegates = [[NSMutableSet alloc] init];
        [_delegates addObject:_resourceRequest.delegate];
    }
    
    return self;
}

+(DownloadOperation*) operationWithDownloadOperation:(DownloadOperation*) operation
{
    if (operation)
    {
        DownloadOperation *newOperation = [[DownloadOperation alloc] initWithRequest:operation.request];
        assert(newOperation);
        newOperation.concurrent = operation.concurrent;
        newOperation.supportPauseResume = operation.supportPauseResume;
        
        return [newOperation autorelease];
    }
    else
    {
        assert(false);
        return nil;
    }
}

-(NSString*) description
{
    return [NSString stringWithFormat:@"DownloadOperation \n%@", self.request];
}

-(BOOL) isEqual:(id)object
{
    if (![object isKindOfClass:[DownloadOperation class]])
    {
        return NO;
    }
    
    if (self == object)
    {
        return YES;
    }
    
    return [self.request isEqual:[object request]];
}

- (BOOL)isConcurrent
{
    return _bIsConcurrent;
}

- (BOOL)isExecuting
{
    return _bExecuting;
}

- (BOOL)isFinished
{
    return _bFinished;
}

-(BOOL) isPaused
{
    return _bPaused;
}

-(void) addDelegate:(id) delegate
{
    assert(delegate);//Check why delegate is nil;
    assert(_delegates);//Check why _delegates is not allocated
    if (delegate)
    {
        [_delegates addObject:delegate];
    }
}

-(NSData*) responseData
{
    if (self.supportPauseResume)
    {
        return [NSData dataWithContentsOfFile:_partialDownloadFile];
    }
    else
    {
        return _responseData;
    }
}


-(void) start
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start)
                               withObject:nil waitUntilDone:NO];
        return;
    }
    
    
    //If operation queue has canceled the operation then cancel the connection and return
    if( _bFinished || [self isCancelled] ) { [self done]; return; }
    
    
    [self willChangeValueForKey:@"isExecuting"];
    _bExecuting = YES;
    _bFinished = NO;
    [self didChangeValueForKey:@"isExecuting"];
    
    _bPaused = NO;
    NSURL *resourceURL = [NSURL URLWithString:[_resourceRequest.resource.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:resourceURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
        
    if(self.supportPauseResume)
    {
        _temporaryFile = [[self createTemporaryDownloadFileForURL:resourceURL] retain];
        assert(_temporaryFile);
        
        if (_temporaryFile)
        {
            unsigned long long downloadedBytes = [_temporaryFile offsetInFile];
            
            if (downloadedBytes > 0)
            {
                NSString *requestRange = [NSString stringWithFormat:@"bytes=%llu-", downloadedBytes];
                [urlRequest setValue:requestRange forHTTPHeaderField:@"Range"];
            }
        }
        else //If we fail to create temporary download file then do not support pause resume facility
        {
            self.supportPauseResume = NO;
        }
    }
    
    [urlRequest addValue:GetContentTypeForPathExtension([resourceURL pathExtension]) forHTTPHeaderField:@"Content-Type"];
    
    [urlRequest setHTTPMethod:@"GET"];
    
    //Check NSURLConnection can handle the request
    if (![NSURLConnection canHandleRequest:urlRequest])
    {
        assert(false);
        NSLog(@"DownloadOperation : NSURLConnection can't handle request %@", urlRequest);
    }
    
    // Create the NSURLConnection--this could have been done in init, but we delayed
    // until no in case the operation was never enqueued or was cancelled before starting
    [_urlConnection release];
    _urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
    
    if (!_urlConnection)
    {
        assert(false);
        NSLog(@"DownloadOperation Error : Not able to create the connection");
    }
    else
    {
        [_urlConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_urlConnection start];
    }
    
    [urlRequest release];
}

-(BOOL) isPartialDownloadFileAvailableForURL:(NSURL*) url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *fileName = [url lastPathComponent];
    assert(fileName);
    
    NSString *downloadDirPath = GetDownloadDirPath();
    assert(downloadDirPath);
    
    NSString *partialDownloadFile = [downloadDirPath stringByAppendingPathComponent:fileName];
    
    if ([fileManager fileExistsAtPath:partialDownloadFile])
    {
        return YES;
    }
    
    return NO;
}

-(NSFileHandle*) createTemporaryDownloadFileForURL:(NSURL*) url
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *fileName = [url lastPathComponent];
    assert(fileName);
    
    NSString *downloadDirPath = GetDownloadDirPath();
    [fileManager createDirectoryAtPath:downloadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    assert(downloadDirPath);
    
    _partialDownloadFile = [[NSString alloc] initWithString:[downloadDirPath stringByAppendingPathComponent:fileName]];
    
    NSFileHandle *fileHandle = nil;
    
    BOOL bCreateNewFile = YES;
    
    if ([fileManager fileExistsAtPath:_partialDownloadFile])
    {
        NSError *error = nil;
        NSDictionary *fileDictionary = [fileManager attributesOfItemAtPath:_partialDownloadFile
                                                                     error:&error];
        if (!error && fileDictionary)
        {
            if ([[fileDictionary objectForKey:NSFileSize] unsignedLongLongValue] <= 0)
            {
                [fileManager removeItemAtPath:_partialDownloadFile error:&error];
                assert(error == nil);
                bCreateNewFile = YES;
            }
        }
    }
    
    if(bCreateNewFile)
    {
        BOOL bCreated = [fileManager createFileAtPath:_partialDownloadFile contents:nil attributes:nil];
        assert(bCreated);
    }
    
    fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_partialDownloadFile];
    [fileHandle seekToEndOfFile];
    
    return fileHandle;
}


-(void) deleteTemporaryDownloadFileForURL:(NSString*) partialDownloadFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:partialDownloadFile])
    {
        NSError *error = nil;
        if (![fileManager removeItemAtPath:partialDownloadFile error:&error])
        {
            NSLog(@"DownloadOperation : Unable to delete the partial downlaoded file %@", error);
            assert(false);
        }
    }
}


-(BOOL) pause
{
    if (!self.supportPauseResume)
    {
        return FALSE;
    }
    else
    {        
        [self willChangeValueForKey:@"isPaused"];
        _bPaused = YES;
        [self didChangeValueForKey:@"isPaused"];
        
        [self canceled];
    }
    
    return TRUE;
}


-(void) restart
{
    if( _urlConnection )
    {
        [_urlConnection cancel];
        [_urlConnection release];
        _urlConnection = nil;
    }
    
    
    [_temporaryFile closeFile];
    [_temporaryFile release];
    _temporaryFile = nil;
    
    //Delete temporary file
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:_partialDownloadFile error:&error];
    
    if (error)
    {
        NSLog(@"DownloadOperation Unable to delete the file %@", error);
        assert(false);
    }
    
    [_responseData release];
    _responseData = nil;
    
    _progress = 0;
    
    [self start];
}

- (void)done
{
    if( _urlConnection )
    {
        [_urlConnection cancel];
        [_urlConnection release];
        _urlConnection = nil;
    }
    
    [_temporaryFile closeFile];
    [_temporaryFile release];
    _temporaryFile = nil;
    
    // Alert anyone that we are finished
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _bExecuting = NO;
    _bFinished  = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

-(void)canceled
{
    [self done];
}


#pragma mark -------------- NSURLConnectionDelegate ------------------

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if([self isCancelled])
    {
        [self canceled];
		return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]])
    {
        // I don't know what kind of request this is!
        return;
    }
    
    _progress = 0;
        
    NSInteger statusCode = [httpResponse statusCode];
    NSUInteger contentSize = [httpResponse expectedContentLength] > 0 ? [httpResponse expectedContentLength] : 0;
    
    //Determine content size for tracking download progress
    if (contentSize == 0)
    {
        _expectedContentLength = LONG_MAX;
    }
    else
    {
        _expectedContentLength = contentSize;
    }
    
    BOOL bUncessfullResponse = NO;
    
    if (self.supportPauseResume)
    {
        switch (statusCode)
        {
            case 206:
            {
                unsigned long long downlaodedBytes = [_temporaryFile offsetInFile];
                
                if (downlaodedBytes <= 0)
                {
                    assert(false);//Why did we get Http 206 response?
                    break;
                }
                
                NSString *range = [httpResponse.allHeaderFields valueForKey:@"Content-Range"];
                NSError *error = nil;
                NSRegularExpression *regex = nil;
                
                // Check to see if the server returned a valid byte-range
                regex = [NSRegularExpression regularExpressionWithPattern:@"bytes (\\d+)-\\d+/\\d+"
                                                                  options:NSRegularExpressionCaseInsensitive
                                                                    error:&error];
                if (error)
                {
                    [_temporaryFile truncateFileAtOffset:0];
                    break;
                }
                
                // If the regex didn't match the number of bytes, start the download from the beginning
                NSTextCheckingResult *match = [regex firstMatchInString:range
                                                                options:NSMatchingAnchored
                                                                  range:NSMakeRange(0, range.length)];
                if (match.numberOfRanges < 2)
                {
                    [_temporaryFile truncateFileAtOffset:0];
                    break;
                }
                
                // Extract the byte offset the server reported to us, and truncate our
                // file if it is starting us at "0".  Otherwise, seek our file to the
                // appropriate offset.
                NSString *byteStr = [range substringWithRange:[match rangeAtIndex:1]];
                unsigned long long bytes = [byteStr longLongValue];
                
                NSLog(@"DownloadOperation : Download Range Information - Byes Downloaded (%llu) Received Range (%llu)", downlaodedBytes, bytes);
                
                if(bytes <= downlaodedBytes)
                {
                    [_temporaryFile seekToFileOffset:bytes];
                     _expectedContentLength += [_temporaryFile offsetInFile];//bytes to download + already downloaded
                    _progress = (NSUInteger)(((float)[_temporaryFile offsetInFile] / _expectedContentLength) * 100);
                }
                else
                {
                    [_temporaryFile truncateFileAtOffset:0];
                    bUncessfullResponse = YES;
                }
                break;
            }
            case 406:
                bUncessfullResponse = YES;
                break;
            default:
                [_temporaryFile truncateFileAtOffset:0];
                break;
        }
        
        if (bUncessfullResponse)
        {
            NSLog(@"DownloadOperation : Failed to resume download for - %@",[_partialDownloadFile lastPathComponent]);
            [self restart];
        }
    }
    else
    {
        _responseData = [[NSMutableData alloc] initWithCapacity: contentSize];
    }
    if( statusCode / 100 != 2 )
    {
        NSLog(@"DownloadOperation : Download failed with error(%i) %@ for resource - %@",statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode],_resourceRequest.resource.url);
        if ([_resourceRequest.delegate respondsToSelector:@selector(downloadDidFail:withErro:)])
        {
            [_resourceRequest.delegate downloadDidFail:self withErro:nil]; //TODO add proper error object
        }
    }
    
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    //TODO: Handle Authentication challenges
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if([self isCancelled])
    {
        [self canceled];
		return;
    }
    else
    {
        NSUInteger lastProgress = _progress;

        if (self.supportPauseResume)
        {
            [_temporaryFile writeData:data];
            [_temporaryFile synchronizeFile];
            _progress = (NSUInteger)(((float)[_temporaryFile offsetInFile] / _expectedContentLength) * 100);
        }
        else
        {
            [_responseData appendData:data];
            _progress = (NSUInteger)(((float)[_responseData length] / _expectedContentLength) * 100);
        }
        
        NSLog(@"DownloadOperation : File <%@>  Bytes Received <%i> Current Progress <%i>",[_resourceRequest.resource.url lastPathComponent], [data length], _progress);
                
        if (abs(_progress - lastProgress) > 0) //Notify only If progress changed by atleast a percent
        {
            for (id delegate in _delegates)
            {
                if ([delegate respondsToSelector:@selector(downloadProgressDidUpdate:)])
                {
                    [delegate performSelectorOnMainThread:@selector(downloadProgressDidUpdate:) withObject:self waitUntilDone:NO];
                }
            }
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //log the error
     NSLog(@"DownloadOperation : Download failed with error - %@ for resource  %@",error,_resourceRequest);
    
    if([self isCancelled])
    {
        [self canceled];
    }
	else
    {
		[_responseData release];
		_responseData = nil;
		[self done];
	}
    
    for (id delegate in _delegates)
    {
        if ([delegate respondsToSelector:@selector(downloadDidFail:withErro:)])
        {
            [delegate downloadDidFail:self withErro:error];
        }
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if([self isCancelled])
    {
        [self canceled];
		return;
    }
    
    if (self.supportPauseResume)
    {
        assert(!_responseData);
        [_temporaryFile seekToEndOfFile];
        unsigned long long bytesDownloaded = [_temporaryFile offsetInFile];
        [_temporaryFile closeFile];
        assert(_partialDownloadFile);
        _responseData = [[NSMutableData alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:_partialDownloadFile]];
        unsigned long long dataSize = [_responseData length];
        
        assert(dataSize != 0);//Why the file size is 0?
        assert(bytesDownloaded != 0);
        self.supportPauseResume = NO;
    }
    
    _progress = 100;
    _resourceRequest.resource.size = [NSNumber numberWithUnsignedInteger:[_responseData length]];
    
    [self done];
    
    //Notify Delegate
    for (id delegate in _delegates)
    {
        if ([delegate respondsToSelector:@selector(downloadDidFinish:)])
        {
            [delegate downloadDidFinish:self];
        }
    }
    
}

-(void)dealloc
{
    //Delete temporary download file
    [self deleteTemporaryDownloadFileForURL:_partialDownloadFile];
        
    [self setObservationInfo:NULL];
    
    [_responseData release];
    [_resourceRequest release];
    [_urlConnection cancel];
    [_urlConnection release];
    [_temporaryFile closeFile];
    [_partialDownloadFile release];
    [_delegates release];
    
    _responseData = nil;
    _resourceRequest = nil;
    _urlConnection = nil;
    _temporaryFile = nil;
    _partialDownloadFile = nil;
    _delegates = nil;
    
    [super dealloc];
}

@end
