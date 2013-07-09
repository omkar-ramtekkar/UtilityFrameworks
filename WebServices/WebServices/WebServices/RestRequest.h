//
//  RestRequest.h
//  
//
//  Created by omkar_ramtekkar on 13/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Parser.h"

@interface RestRequest : NSOperation
{
@private
    BOOL            _bFinished;
    BOOL            _bExecuting;
    NSUInteger      _iRetryAttempt;
    BOOL            _bIsConcurrent;
    NSUInteger      _responseCode;
    BOOL            _usePostMethod;

    
    NSString        *_methodName;
    NSMutableData   *_responseData;
    NSURL           *_serverURL;
    NSURLConnection *_urlConnection;
    NSArray         *_attrs;
    NSArray         *_values;
    id               _delegate;
    NSMutableDictionary    *_outputDict;
    id<Parser>       _parser;
    
}

@property(readonly, nonatomic) NSString *methodName;
@property(readonly, nonatomic) NSData *responseData;
@property(retain, nonatomic) NSURL *serverURL;
@property(readonly, nonatomic) NSArray *attrs;
@property(readonly, nonatomic) NSArray *values;
@property(retain, nonatomic) id delegate;
@property(nonatomic, assign) BOOL concurrent;
@property(nonatomic, assign) NSUInteger responseCode;
@property(nonatomic, retain) NSDictionary *outputDict;
@property(nonatomic, assign) BOOL usePostMethod;
@property(nonatomic, retain) id<Parser> parser;

-(id) initWithMethodName:(NSString*) methodName withAttrs:(NSArray*) attrs andValues:(NSArray*) values;

@end
