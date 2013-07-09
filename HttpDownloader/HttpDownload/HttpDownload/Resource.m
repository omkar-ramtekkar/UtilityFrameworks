//
//  ResourceEntity.m

//
//  Created by Yashodhan on 14/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import "Resource.h"


@implementation Resource

@synthesize physicalPath;
@synthesize size;
@synthesize type;
@synthesize url;
@synthesize version;

-(BOOL) isEqual:(id)object
{
    if (![object isKindOfClass:[Resource class]])
    {
        return NO;
    }
    
    if (self == object)
    {
        return YES;
    }
    
    if ([self.url isKindOfClass:[NSURL class]] || [[object url]  isKindOfClass:[NSURL class]])
    {
        assert(false);
    }
    
    BOOL bEqual = [[self url] isEqual:[(Resource*)object url]];
    
    if (bEqual && ([self physicalPath] && [(Resource*)object physicalPath]))
    {
        bEqual &= [[self physicalPath] isEqual:[object physicalPath]];
    }
    
    if (bEqual && (self.version && [(Resource*)object version]))
    {
        bEqual &= [[self version] isEqual:[(Resource*)object version]];
    }
    
    return bEqual;
}

- (id)copyWithZone:(NSZone *) __unused zone
{
    Resource* copy = [[Resource alloc] init];
    if (copy)
    {
        copy.physicalPath = [[self.physicalPath copy] autorelease];
        copy.size = [[self.size copy] autorelease];
        copy.type = [[self.type copy] autorelease];
        copy.url = [[self.url copy] autorelease];
        copy.version = [[self.version copy] autorelease];
    }
    return copy;
}

-(NSString*) description
{
    return [NSString stringWithFormat:@"Resource {url : %@ \n path : %@ \n size : %@\n}",self.url, self.physicalPath, self.size];
}

@end
