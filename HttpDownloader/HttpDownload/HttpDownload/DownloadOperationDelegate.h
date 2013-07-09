//
//  DownloadOperationDelegate.h

//
//  Created by omkar_ramtekkar on 16/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DownloadOperation;

@protocol DownloadOperationDelegate <NSObject>

@optional

-(void) downloadDidFail:(DownloadOperation*) operation withErro:(NSError*) error;

-(void) downloadDidStart:(DownloadOperation*) operation;
-(void) downloadDidFinish:(DownloadOperation*) operation;
-(void) downloadProgressDidUpdate:(DownloadOperation*) operation;

@end
