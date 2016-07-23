//
//  AppDelegate.m
//  Revolut
//
//  Created by Vadim on 19/07/16.
//  Copyright © 2016 Brysov Corp. All rights reserved.
//

#import "AppDelegate.h"
#import "AFNetworkActivityLogger.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelDebug];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {
    
}

@end
