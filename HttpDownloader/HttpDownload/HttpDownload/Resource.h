//
//  ResourceEntity.h

//
//  Created by Yashodhan on 14/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

/**
 * @class Resource
 * @description Resource is a generic class to represent a resource, resource can be an Image, Video or Audio, XML or Other
 * @property physicalPath This contains the physical path of resource
 * Note : This is an optional property, this will contain actual physical path once the resource is being downloaded
 * @property size This represents the size of resource, the size will be initialised after downloading the resource
 * @property url This is a required property, depending on url @class DownloadManager will download the resource
 * @property type This represents the type of resource, this is a required property
 * @property version This represents the version of resource, this is an optional property
 */


#import <Foundation/Foundation.h>

typedef enum
{
    Image = 1,
    Audio,
    Video,
    XML,
    Other
} ResourceType;


@interface Resource : NSObject<NSCopying>

@property (nonatomic, retain) NSString *physicalPath;
@property (nonatomic, retain) NSNumber *size;
@property (nonatomic, retain) NSNumber *type;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSNumber *version;

@end
