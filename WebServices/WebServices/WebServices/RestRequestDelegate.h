//
//  RestRequestDelegate.h
//  
//
//  Created by omkar_ramtekkar on 14/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RestRequest;

@protocol RestRequestDelegate <NSObject>

@optional
-(void) serviceWillExecute:(RestRequest*) service;
-(void) serviceDidFinish:(RestRequest*) service;
-(void) serviceDidFail:(RestRequest*) service withError:(NSError*) error;

@end
