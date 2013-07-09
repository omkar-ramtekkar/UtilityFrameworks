//
//  AppDelegate.m
//  RestWebService_Sample1
//
//  Created by omkar_ramtekkar on 21/06/13.
//  Copyright (c) 2013 omkar_ramtekkar. All rights reserved.
//

#import "AppDelegate.h"
#import <WebServices/WebServices.h>
#import "ProgramParser.h"
#import "Constants.h"

@implementation AppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    [self performSelectorInBackground:@selector(runSampleRequest) withObject:nil];
    
    
    return YES;
}

-(void) runSampleRequest
{
    //Sample rest request using GET
    {
        RestRequest* request = [[RestRequest alloc] initWithMethodName:@"getListOfYogaPointPrograms"
                                                             withAttrs:nil
                                                             andValues:nil];
        request.usePostMethod = NO;
        request.serverURL = [NSURL URLWithString:@"http://www.yogapoint.com/ypwebapi/api"];
        request.concurrent = NO;
        ProgramParser *parser = [[ProgramParser alloc] initWithData:nil];
        request.parser = parser;
        [parser release];
        
        [request start];
        [request waitUntilFinished];
        
        NSLog(@"Response Data : %@", [[[NSString alloc] initWithData:request.parser.data encoding:NSUTF8StringEncoding] autorelease]);
    }
    
    //Sample rest request using POST
    {
        RestRequest* request = [[RestRequest alloc] initWithMethodName:@"getListOfYogaPointCategories"
                                                             withAttrs:nil
                                                             andValues:nil];
        request.usePostMethod = YES;
        request.serverURL = [NSURL URLWithString:@"http://psng795/YogaPoint/Service.asmx"];
        request.concurrent = NO;
        ProgramParser *parser = [[ProgramParser alloc] initWithData:nil];
        request.parser = parser;
        [parser release];
        
        [request start];
        [request waitUntilFinished];
        
        NSLog(@"Response Data : %@", [[[NSString alloc] initWithData:request.parser.data encoding:NSUTF8StringEncoding] autorelease]);
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
