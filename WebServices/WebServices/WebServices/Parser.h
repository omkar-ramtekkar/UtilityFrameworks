//
//  ParserDelegate.h
//  
//
//  Created by omkar_ramtekkar on 23/05/13.
//  Copyright (c) 2013 persistent. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ParserDelegate <NSObject>

@optional
-(void) parserDidStart:(id) parser;
-(void) parserDidFinish:(id) parser;
-(void) parserDidFailWithError:(id) parser error:(NSError*) error;

@end


@protocol Parser <NSXMLParserDelegate>

@required
-(id) initWithData:(NSData*) data;
-(void) parse;

@property(nonatomic, assign) BOOL success;
@property(nonatomic, readonly) NSDictionary *outputData;
@property(nonatomic, copy) NSData *data;

@end