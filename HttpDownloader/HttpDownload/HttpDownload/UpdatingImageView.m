//
//  UpdatingImageView.m

//
//  Created by Om on 25/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import "UpdatingImageView.h"
#import "DownloadOperation.h"
#import "OfflineStorageModel.h"
#import "ResourceRequest.h"
#import "Resource.h"
#import "DownloadManager.h"

@implementation UpdatingImageView

@dynamic url;
@synthesize useCacheIfExists = _useCacheIfExists;
@synthesize placeholderImage = _placeholder;


-(void) setUrl:(NSURL *)url
{
    [_url release];
    _url = [url copy];
    
    if (!_url)
    {
        return;
    }
    
    if (_useCacheIfExists)
    {

        Resource *resource = [[OfflineStorageModel sharedInstance] getResourceForURL:_url];
        
        if (resource)
        {
            self.image = [[OfflineStorageModel sharedInstance] getDataAssociatedWithResource:resource];
        }
    }
    else
    {
        self.image = self.placeholderImage;
        
        Resource* resource = [[Resource alloc] init];
        resource.url = [[self url] absoluteString];
        resource.type = [NSNumber numberWithInt:Image];
        
        ResourceRequest* request = [[ResourceRequest alloc] init];
        request.resource = resource;
        request.delegate = self;
        request.supportPauseResume = YES;
        
        assert(_screenName);//Why screen name is nil? Please set it before setting the url.
        
        [[DownloadManager sharedInstance] downloadResource:request overriteIfExists:_useCacheIfExists context:_screenName];
        
        [request release];
        [resource release];
    }
}

-(NSURL*) url
{
    return [[_url copy] autorelease];
}

-(void) downloadDidFail:(DownloadOperation*)__unused operation withErro:(NSError*)__unused error
{
    self.image = self.placeholderImage;
    [self setNeedsDisplay];
}

-(void) downloadDidStart:(DownloadOperation*)__unused operation
{
    self.image = self.placeholderImage;
    [self setNeedsDisplay];
}

-(void) downloadDidFinish:(DownloadOperation*) operation
{
    Resource *resource = operation.request.resource;
    if (!resource)
    {
        resource = [[OfflineStorageModel sharedInstance] getResourceForURL:_url];
    }
    
    assert(resource);
    if (resource)
    {
        UIImage *img = [[OfflineStorageModel sharedInstance] getDataAssociatedWithResource:resource];
        assert(img);
        self.image = img;
    }
    else
    {
        self.image = self.placeholderImage;
    }
    
    [self setNeedsDisplay];

}

-(void) downloadProgressDidUpdate:(DownloadOperation*) operation
{
    self.image = [UIImage imageWithData:operation.responseData];
    [self setNeedsDisplay];
}

-(void) dealloc
{
    [_url release];
    [_placeholder release];
    [_screenName release];
    
    _url = nil;
    _placeholder = nil;
    _screenName = nil;
    
    [super dealloc];
}

@end
