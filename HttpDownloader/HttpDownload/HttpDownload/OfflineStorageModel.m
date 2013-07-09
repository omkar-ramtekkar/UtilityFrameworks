//
//  OfflineStorageModel.m

//
//  Created by omkar_ramtekkar on 13/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import "OfflineStorageModel.h"
#import "Resource.h"
#import "DownloadOperation.h"
#import "ResourceRequest.h"
#import "Constants.h"
#import <limits.h>

static NSUInteger OFFLINE_STORAGE_CAPACITY = 10485760; //default 10 MB

static OfflineStorageModel* offlineStorageModel_g = nil;

NSString* GetDocumentDirPath()
{
    static NSString *docDirPath_g = nil;
    if (docDirPath_g)
    {
        return docDirPath_g;
    }
    else
    {
        //Offline Dir Path
        docDirPath_g = [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] path] retain];
    }
    return docDirPath_g;
}

@interface OfflineStorageModel()

-(void) initialize;
-(id) getDataForResource:(Resource*) resorce;
-(void) resourceDownloaded:(NSNotification*) notitification;
-(void) handleLowMemoryWarining:(NSNotification*) note;
-(id) createDataForResource:(Resource*) resource;
-(void) registerNotifications;
-(void) unregisterNotifications;
-(BOOL) saveData:(NSData*) data forResource:(Resource*) resource;

@end


@implementation OfflineStorageModel

+(OfflineStorageModel*) sharedInstance
{
    if (offlineStorageModel_g)
    {
        return offlineStorageModel_g;
    }
    else
    {
        static dispatch_once_t pred;
        dispatch_once(&pred,^{
            offlineStorageModel_g = [[OfflineStorageModel alloc] init];
            [offlineStorageModel_g initialize];
            assert(offlineStorageModel_g);
        });
        
        return offlineStorageModel_g;
    }
}

-(void) initialize
{
    assert(!_resources && !_imageCache && !_audioCache && !_videoCache);
    
    //Allocate
    _resources = [[NSMutableArray alloc] init];
    _imageCache = [[NSCache alloc] init];
    _audioCache = [[NSCache alloc] init];
    _videoCache = [[NSCache alloc] init];
    _dirPath = [[NSString alloc] init];
    
    //Configure
    [_imageCache setCountLimit:20];
    [_imageCache setTotalCostLimit:OFFLINE_STORAGE_CAPACITY];
    
    [_audioCache setCountLimit:10];
    [_audioCache setTotalCostLimit:OFFLINE_STORAGE_CAPACITY];
    
    [_videoCache setCountLimit:5];
    [_videoCache setTotalCostLimit:OFFLINE_STORAGE_CAPACITY];
    
    //Offline Dir Path
    NSString *docDirPath = GetDocumentDirPath();
    
    _dirPath = [[docDirPath stringByAppendingPathComponent:@"Resources"] retain];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:_dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    [self registerNotifications];

}

-(void) registerNotifications
{
    [self unregisterNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resourceDownloaded:) name:kNotificationResourceDownloaded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLowMemoryWarining:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

-(void) unregisterNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) releaseInstance
{
    [self unregisterNotifications];
    
    [offlineStorageModel_g release];
}


+(void) setOfflineStorageCapacity:(NSUInteger) megabytes
{
    assert(megabytes > kOfflineStorageLimit); //should not be greater than kOfflineStorageLimit
    if (megabytes > kOfflineStorageLimit)
    {
        OFFLINE_STORAGE_CAPACITY = kOfflineStorageDefaultSize * 1024 * 1024;
    }
    else
    {
        OFFLINE_STORAGE_CAPACITY = megabytes * 1024 * 1024;
    }
}

+(NSUInteger) getOfflineStorageCapacity
{
    return OFFLINE_STORAGE_CAPACITY;
}

-(BOOL) isResourceAvailable:(Resource*) resource;
{
    BOOL bAvailable = NO;
    
    if([_resources containsObject:resource])
    {
        bAvailable = YES;
    }
    
    return bAvailable;
}

-(Resource*) getResourceForURL:(NSURL*) url
{
    Resource *completeResource = nil;
    NSString *absoluteURLString = [url absoluteString];
    for (Resource *resource in _resources) 
    {
        if([resource.url isEqual: absoluteURLString])
        {
            completeResource = [resource copy];
            break;
        }
    }
    
    return [completeResource autorelease];
}

-(BOOL) isValidResource:(Resource*) resource
{
    Resource *completeResource = [self getResourceForURL:[NSURL URLWithString: resource.url]];
    return [[NSFileManager defaultManager] fileExistsAtPath:completeResource.physicalPath];
}

-(BOOL) validateResourceAndUpdateInternalValues:(Resource*) resourceToValidate
{
    assert(resourceToValidate.url);
    
    if (![self isValidResource:resourceToValidate])
    {
        NSString *filename = [resourceToValidate.url lastPathComponent];
        assert(filename);
        
        NSString *filePath = [_dirPath stringByAppendingPathComponent:filename];
        
        resourceToValidate.physicalPath = filePath;
    }
    
    return YES;
}

-(id) getDataForResource:(Resource*) resource
{
    Resource *completeResource = [self getResourceForURL:[NSURL URLWithString:resource.url]];
    if([self isValidResource:completeResource])
    {
        id resourceData = nil;
        switch ([resource.type integerValue])
        {
            case Image:
                resourceData = [_imageCache objectForKey:resource.physicalPath];
                break;
            case Audio:
                resourceData = [_audioCache objectForKey:resource.physicalPath];
                break;
            case Video:
                resourceData = [_videoCache objectForKey:resource.physicalPath];
                break;
            default:
                assert(false);
        }
        
        if (!resourceData)
        {
            resourceData = [self createDataForResource:completeResource];
        }
        
        return resourceData;
    }
    else
    {
        assert(false);//An invalid resource request
    }
    return nil;
}

-(BOOL) deleteResource:(Resource*) resource
{
    BOOL bAvailable = [self isResourceAvailable:resource];
    if (bAvailable)
    {
        @synchronized(_resources)
        {
            [_resources removeObject:resource];
            NSError *error = nil;
            BOOL bDeleteSuccess = [[NSFileManager defaultManager] removeItemAtPath:resource.physicalPath error:&error];
            if (!bDeleteSuccess)
            {
                NSLog(@"OfflineStorageModel : Unable to delete the resource file - error : %@", error);
            }
        }
        
        switch ([resource.type integerValue])
        {
            case Image:
            {
                @synchronized(_imageCache)
                {
                    [_imageCache removeObjectForKey:resource.physicalPath];
                }
            }
                break;
            case Audio:
            {
                @synchronized(_audioCache)
                {
                    [_audioCache removeObjectForKey:resource.physicalPath];
                }
            }
                break;
            case Video:
            {
                @synchronized(_videoCache)
                {
                    [_videoCache removeObjectForKey:resource.physicalPath];
                }
            }
                break;
            default:
                assert(false);//Handle Case
        }
    }
    
    return bAvailable;
}


-(BOOL) saveData:(NSData*) data forResource:(Resource*) resource
{
    assert(data && resource);
    assert(resource.physicalPath);
    
    if (!resource.physicalPath)
    {
        NSString *filename = [resource.url lastPathComponent];
        NSString *filePath = [_dirPath stringByAppendingPathComponent:filename];
        resource.physicalPath = filePath;
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:resource.physicalPath error:nil];
    return [data writeToFile:resource.physicalPath atomically:YES];
}

-(id) createDataForResource:(Resource*) resource
{
    switch ([resource.type integerValue])
    {
        case Image:
        {
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:resource.physicalPath];
            assert(img);
            if (img)
            {
                [_imageCache setObject:img forKey:resource.physicalPath cost:[resource.size unsignedIntegerValue]];
            }
            return [img autorelease];
        }
        case Audio:
            assert(false);//No need to create data for Audio file
            return nil;
        case Video:
            assert(false);//No need to create data for Video file
            return nil;
        default:
            assert(false);//Why control is coming here?
                          //Check Resource type value
            return nil;
    }
}

-(void) resourceDownloaded:(NSNotification*) notitification
{
    DownloadOperation *operation = [notitification object];
    if (operation)
    {
        assert(operation.responseData && operation.request);
        Resource* resource = [operation.request.resource copy];
        @synchronized(_resources)
        {
            //While saving resource we will have to validate all properties of resource
            //Make sure Resource has all valid properties before adding it to resources list
            //Check if resource is already exists, if yes then delete the existing resource
            BOOL bExists = [_resources containsObject:resource];
            
            NSString *filename = [resource.url lastPathComponent];
            
            assert(filename);
            
            NSString *filePath = [_dirPath stringByAppendingPathComponent:filename];
            
            resource.physicalPath = filePath;
            
            if (bExists)
            {
                [_resources removeObject:resource];
            }
            
            assert(resource.physicalPath && resource.size && resource.type && resource.url);
            if (resource.physicalPath && resource.size && resource.type && resource.url)
            {
                [_resources addObject: resource];
            }
        }
        
        //Save the resource to App Document Directry
        if([self saveData:operation.responseData forResource:resource])
        {
            //TODO Update Core Data
        }
        
        [resource release];
    }
}

-(void) handleLowMemoryWarining:(NSNotification*)__unused note
{
    [_videoCache removeAllObjects];
    [_audioCache removeAllObjects];
    [_imageCache removeAllObjects];
}

-(id) getDataAssociatedWithResource:(Resource*) resource
{
    return [self getDataForResource:resource];
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_resources release];
    [_imageCache release];
    [_audioCache release];
    [_videoCache release];
    [_dirPath release];
    
    [super dealloc];
}

@end
