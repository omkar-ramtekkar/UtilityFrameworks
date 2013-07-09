//
//  ResourceRequest.m

//
//  Created by omkar_ramtekkar on 16/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import "ResourceRequest.h"
#import "Resource.h"

@implementation ResourceRequest

@synthesize resource = _resource;
@synthesize delegate = _delegate;
@synthesize supportPauseResume = _supportPauseResume;


-(BOOL) isEqual:(id)object
{
    if (![object isKindOfClass:[ResourceRequest class]])
    {
        return NO;
    }
    
    if (self == object)
    {
        return YES;
    }
    
    return [self.resource isEqual:[object resource]];
}

- (id)copyWithZone:(NSZone *)zone
{
    ResourceRequest* copy = [[ResourceRequest alloc] init];
    if (copy)
    {
        copy.resource = [[self.resource copy] autorelease];
        copy.delegate = self.delegate;
        copy.supportPauseResume = self.supportPauseResume;
    }
    
    return copy;
}

-(void) dealloc
{
    [_resource release];
    [_delegate release];
    
    [super dealloc];
}

-(NSString*) description
{
    return [NSString stringWithFormat:@"ResourceRequest \n%@",[self.resource description]];
}

@end
