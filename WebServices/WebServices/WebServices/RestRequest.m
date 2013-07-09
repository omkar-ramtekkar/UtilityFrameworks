//
//  RestRequest.m
//  
//
//  Created by omkar_ramtekkar on 13/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import "RestRequest.h"
#import "RestMessage.h"
#import "RestRequestDelegate.h"
#import "Parser.h"

@interface RestRequest()
-(void) resetDelegate;
@end


@implementation RestRequest

@synthesize methodName = _methodName;
@synthesize responseData = _responseData;
@synthesize serverURL = _serverURL;
@synthesize attrs = _attrs;
@synthesize values = _values;
@synthesize delegate = _delegate;
@synthesize concurrent = _bIsConcurrent;
@synthesize responseCode = _responseCode;
@synthesize outputDict = _outputDict;
@synthesize usePostMethod = _usePostMethod;


-(id) initWithMethodName:(NSString*) methodName withAttrs:(NSArray*) attrs andValues:(NSArray*) values
{
    if (self = [super init])
    {
        _methodName = [[NSString alloc] initWithString:methodName];
        _attrs = [[NSArray alloc] initWithArray:attrs];
        _values = [[NSArray alloc] initWithArray:values];
        _responseData = nil;
        _bFinished = NO;
        _bExecuting = NO;
        _iRetryAttempt = 0;
        _bIsConcurrent = YES;
        _delegate = nil;
        _serverURL = nil;
        _urlConnection = nil;
        _responseCode = 0;
        _outputDict = nil;
        _usePostMethod = NO;
        _parser = nil;
    }
    
    return self;
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


-(void) start
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start)
                               withObject:nil waitUntilDone:NO];
        return;
    }
    
    
    ++_iRetryAttempt;
    //If operation queue has canceled the operation then cancel the connection and return
    if( _bFinished || [self isCancelled] ) { [self done]; return; }
    
    
    [self willChangeValueForKey:@"isExecuting"];
    _bExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
        
    RestMessage* restMessage = [[RestMessage alloc] initWithMethodName:self.methodName withAttrs:self.attrs andValues:self.values formatStyle:_usePostMethod ? POST_BODYSTRING : GET_QUERYSTRING];
    
    //Create service url with the format - "base url/metyhod-name HTTP/1.1"
    if (!self.serverURL)
    {
        NSLog(@"RestRequest : Error - serverURL not specified");
        assert(false);
        return;
    }
    
    NSMutableURLRequest *urlRequest = nil;
    
    if (_usePostMethod)
    {
        urlRequest = [[NSMutableURLRequest alloc] initWithURL:self.serverURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];;
        [urlRequest setHTTPMethod:@"POST"];
        [urlRequest setHTTPBody:[restMessage.message dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else
    {
        NSLog(@"%@",[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverURL, restMessage.message]]);
        urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", self.serverURL, restMessage.message]]
                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
        [urlRequest setHTTPMethod:@"GET"];
    }
    
    
    NSString *msgLength = [NSString stringWithFormat:@"%d",[restMessage.message length]];
    
    if (_usePostMethod)
    {
        [urlRequest addValue:@"application/x-www-form-urlencoded;" forHTTPHeaderField:@"Content-Type"];
        [urlRequest addValue:msgLength forHTTPHeaderField:@"Content-Length"];
    }
    else
    {
        [urlRequest addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    }
    
    
    // Create the NSURLConnection--this could have been done in init, but we delayed
    // until no in case the operation was never enqueued or was cancelled before starting
    [_urlConnection release];
    _urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
    
    if (!_urlConnection)
    {
        NSLog(@"Error : Not able to create the connection");
    }
    else
    {
        [_urlConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [_urlConnection start];
    }
        
    [urlRequest release];
    [restMessage release];
}


- (void)done
{
    if( _urlConnection )
    {
        [_urlConnection cancel];
        [_urlConnection release];
        _urlConnection = nil;
    }
    
    // Alert anyone that we are finished
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    _bExecuting = NO;
    _bFinished  = YES;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

-(void) resetDelegate
{
    [_delegate release];
    _delegate = nil;
}


-(void)canceled
{
    [self done];
}


#pragma mark -------------- NSURLConnectionDelegate ------------------

- (void)connection:(NSURLConnection *)__unused connection didReceiveResponse:(NSURLResponse *)response
{
    if([self isCancelled])
    {
        [self canceled];
		return;
    }
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    _responseCode = [httpResponse statusCode];
    
    if( _responseCode / 100 == 2 )
    {
        NSUInteger contentSize = [httpResponse expectedContentLength] > 0 ? [httpResponse expectedContentLength] : 0;
        _responseData = [[NSMutableData alloc] initWithCapacity: contentSize];
    }
    else
    {
        NSUInteger contentSize = [httpResponse expectedContentLength] > 0 ? [httpResponse expectedContentLength] : 0;
        _responseData = [[NSMutableData alloc] initWithCapacity: contentSize];
        
        NSLog(@"%@", [NSString stringWithFormat:@"RestRequest : %@ HTTP Error: %@(%i)",_methodName, [NSHTTPURLResponse localizedStringForStatusCode:_responseCode], _responseCode]);
        
        if ([self.delegate respondsToSelector:@selector(serviceDidFail:withError:)])
        {
            [self.delegate serviceDidFail:self withError:nil];
        }
        [self resetDelegate];
    }
    
}

-(void)connection:(NSURLConnection *)__unused connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)__unused challenge
{
    //TODO: Handle Authentication challenges
}

- (void)connection:(NSURLConnection *)__unused connection didReceiveData:(NSData *)data
{
    if([self isCancelled])
    {
        [self canceled];
		return;
    }
    else
    {
        [_responseData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)__unused connection didFailWithError:(NSError *)error
{
    //log the error
    NSLog(@"Rest Service %@ : Connection failed! Error - %@ %@",self.methodName, [error localizedDescription],[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    
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
    
    if ([self.delegate respondsToSelector:@selector(serviceDidFail:withError:)])
    {
        [self.delegate serviceDidFail:self withError:error];
    }
    
    [self resetDelegate];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)__unused connection
{
    if([self isCancelled])
    {
        [self canceled];
		return;
    }

    if (_parser)
    {
        [self performSelectorInBackground:@selector(parseResponse) withObject:nil]; 
    }
}

-(void) parseResponse
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    assert(_parser);//Check parser factory and create parser for service
    _parser.data = _responseData;
    [_parser parse];

    assert(_parser.success); //Parsing should be successful
    
    _outputDict = [[NSMutableDictionary alloc] initWithDictionary:_parser.outputData];
    
    NSUInteger cound = [_attrs count];
    
    for (NSUInteger index = 0; index < cound; ++index)
    {
        [_outputDict setObject:[_values objectAtIndex:index] forKey:[_attrs objectAtIndex:index]];
    }
    
    if (_parser.success)
    {
        if ([self.delegate respondsToSelector:@selector(serviceDidFinish:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate serviceDidFinish:self];
            });
        }
    }
    else
    {
        if ([self.delegate respondsToSelector:@selector(serviceDidFail:withError:)])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate serviceDidFail:self withError:nil];
            });
        }
    }
    [pool drain];
    
	[self done];
    [self resetDelegate];
}

-(void)dealloc
{
    [_attrs release];
    [_values release];
    [_methodName release];
    [_responseData release];
    [_serverURL release];
    [_delegate release];
    [_urlConnection cancel];
    [_urlConnection release];
    [_outputDict release];
    [_parser release];
    
    _attrs = nil;
    _values = nil;
    _methodName = nil;
    _responseData = nil;
    _serverURL = nil;
    _delegate = nil;
    _urlConnection = nil;
    _outputDict = nil;
    _parser = nil;
    
    [super dealloc];
}

#if EnableUTC
+(void) test
{
    NSArray* atts = [NSArray arrayWithObjects:kServiceAttributeUserID, kServiceAttributePassword, kServiceAttributeDeviceID, nil];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
       
    NSArray* values = [NSArray arrayWithObjects:[userDefaults objectForKey:kServiceAttributeUserID], [userDefaults objectForKey:kServiceAttributePassword], @"12345", nil];
    
    RestRequest *request = [[RestRequest alloc] initWithMethodName:kServiceNameDoLogin withAttrs:atts andValues:values];
    
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    [queue addOperation:request];
    [queue waitUntilAllOperationsAreFinished];
    
    LogNSData(request.responseData);
    
    [queue release];
    [request release];
    
}

#endif
@end
