//
//  RestMessage.h
//  
//
//  Created by omkar_ramtekkar on 13/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    GET_QUERYSTRING = 0,
    POST_BODYSTRING
} FormatStyle;


@interface RestMessage : NSObject
{
@private
    NSMutableString *_requestString;
    FormatStyle     _style;
}

@property(nonatomic, readonly) NSString *message;

-(id) initWithMethodName:(NSString*) methodName withAttrs:(NSArray*) attrs andValues:(NSArray*) values formatStyle:(FormatStyle) style;

@end
