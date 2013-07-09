//
//  OfflineStorageModel.h

//
//  Created by omkar_ramtekkar on 13/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

/**
 * @class OfflineStorageModel
 * @description This class manages all the offline resources, after downloading a resource this, class manages takes care to manage it.
 * to download any resource
 */

@class Resource;

@interface OfflineStorageModel : NSObject
{
@private
    NSString        *_dirPath;
    NSMutableArray  *_resources;
    NSCache         *_imageCache;
    NSCache         *_audioCache;
    NSCache         *_videoCache;
}


+(OfflineStorageModel*) sharedInstance;
-(void) releaseInstance;

/**
 * Set the offline storage capacity
 */
+(void) setOfflineStorageCapacity:(NSUInteger) megabytes;
+(NSUInteger) getOfflineStorageCapacity;

/**
 * Returns YES if OfflineStorageModel contains the resource object
 */
-(BOOL) isResourceAvailable:(Resource*) resource;

/**
 * Returns YES if file is present in local storage at given physiscalPath property of resource, otherwise returns NO
 */
-(BOOL) isValidResource:(Resource*) resource;

/**
 * Returns data associated with the resource.
 */
-(id) getDataAssociatedWithResource:(Resource*) resource;

/**
 * Returns Resource object for mapped with given url.
 */
-(Resource*) getResourceForURL:(NSURL*) url;

-(BOOL) validateResourceAndUpdateInternalValues:(Resource*) resourceToValidate;
-(BOOL) deleteResource:(Resource*) resource;


@end
