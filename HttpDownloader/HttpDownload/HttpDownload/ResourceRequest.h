//
//  ResourceRequest.h

//
//  Created by omkar_ramtekkar on 16/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * @class ResourceRequest
 * @description ResourceResourceRequest is a generic class to represent a request for a resource, 
 * while downloading the resource, @class DownloadOperation will call the @protocol DownloadOperationDelegate methods
 * @property resource represents the resource to be downloaded, this is a required property
 * @property delegate define delegate for download process if you want to accept the DownloadOperationDelegate methods, this is an optional property
 * @property supportPauseResume Set YES if you want the pause and resume facility for resource, default value is NO
 */

@class Resource;

@interface ResourceRequest : NSObject<NSCopying>

@property(nonatomic, retain) Resource *resource;
@property(nonatomic, retain) id delegate;
@property(nonatomic, assign) BOOL supportPauseResume;

@end
