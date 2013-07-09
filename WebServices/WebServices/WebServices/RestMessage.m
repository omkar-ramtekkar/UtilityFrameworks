//
//  RestMessage.m
//  
//
//  Created by omkar_ramtekkar on 13/05/13.
//  Copyright (c) 2013. All rights reserved.
//

#import "RestMessage.h"

@interface RestMessage()

-(void) initializeRequestString:(NSString*) methodName withAttrs:(NSArray*) attrs andValues:(NSArray*) values;
-(NSString*) formatRestRequestWithParamater:(NSString*)parameterName andValue:(id) value;

@end

@implementation RestMessage

@synthesize message = _requestString;

-(id) initWithMethodName:(NSString*) methodName withAttrs:(NSArray*) attrs andValues:(NSArray*) values formatStyle:(FormatStyle) style
{
    self = [super init];
    if (self)
    {
        _style = style;
        [self initializeRequestString:methodName withAttrs:attrs andValues:values];
    }
    
    return self;
}

-(void) initializeRequestString:(NSString*) methodName withAttrs:(NSArray*) attrs andValues:(NSArray*) values
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    [_requestString release];
    
    _requestString =  [[NSMutableString alloc] init];
    
    if (_style == GET_QUERYSTRING)
    {
        [_requestString appendFormat:@"%@", methodName];
    }
    
    
    BOOL bFirstKey = YES;
    NSUInteger iCount = [attrs count];
    
    for (NSUInteger iIndex=0; iIndex<iCount; ++iIndex)
    {
        NSString* keyValueString = [self formatRestRequestWithParamater:[attrs objectAtIndex:iIndex] andValue:[values objectAtIndex:iIndex]];
        
        if(bFirstKey)
        {
            if (_style == GET_QUERYSTRING)
            {
                [_requestString appendFormat:@"?%@", keyValueString];
            }
            else
            {
                [_requestString appendString:keyValueString];
            }
            bFirstKey = NO;
        }
        else
        {
            [_requestString appendFormat:@"&%@",keyValueString];
        }
    }
    
    [pool drain];
}

-(NSString*) formatRestRequestWithParamater:(NSString*)parameterName andValue:(id) value
{
    
    if (!parameterName || !value)
    {
        NSLog(@"Can't create RestRequest String - Reason: Empty parameterName");
        return nil;
    }
    //First create the parameter list
    NSMutableString* formattedParameterValueList = nil;
    if ([value respondsToSelector:@selector(stringValue)])
    {
        formattedParameterValueList = [NSMutableString stringWithFormat:@"%@", [(NSNumber*)value stringValue]];
    }
    else if ([value isKindOfClass:[NSString class]])
    {
        formattedParameterValueList = [NSMutableString stringWithFormat:@"%@", value];
    }
    else if ((NSArray*) value)
    {
        formattedParameterValueList = [[[NSMutableString alloc] init] autorelease];
        
        BOOL bIsFirstValue = YES;
        
        for (id obj in (NSArray*)value)
        {
            if ([obj respondsToSelector:@selector(stringValue)])
            {
                if (bIsFirstValue)
                {
                    [formattedParameterValueList appendString:[NSString stringWithFormat:@"%@", [(NSNumber*)obj stringValue]]];
                }
                else
                {
                    [formattedParameterValueList appendString:[NSString stringWithFormat:@",%@", [(NSNumber*)obj stringValue]]];
                }
            }
            else if ([obj isKindOfClass:[NSString class]])
            {
                if (bIsFirstValue)
                {
                    [formattedParameterValueList appendString:[NSString stringWithFormat:@"%@", obj]];
                }
                else
                {
                    [formattedParameterValueList appendString:[NSString stringWithFormat:@",%@", obj]];
                }
                
            }
            else
            {
                NSLog(@"Class Type not supported: %@", [obj class]);
                assert(false);
            }
            
            bIsFirstValue = NO;
        }
    }
    else
    {
        assert(false); //Handle the case separately
    }
    NSString* formattedRestRequest = [NSString stringWithFormat:@"%@=%@",parameterName, formattedParameterValueList];
    return formattedRestRequest;
}

-(void) dealloc
{
    [_requestString release];
    _requestString = nil;
    
    [super dealloc];
}

@end
