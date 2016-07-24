#import <Reachability/Reachability.h>
#import "CheckNetVM.h"
#import "Transport.h"
#import "AppDelegate.h"


static NSCondition *checkerLock = nil;
static NSOperationQueue *checkQueue = nil;
static BOOL hasConnection;
static Reachability *reach;


static void initReachability() {
    checkerLock = [[NSCondition alloc] init];
    [checkerLock lock];
    reach = [Reachability reachabilityWithHostname:@"app.chgk.online"];
    reach.reachableBlock = ^(Reachability *reach_) {
        NSLog(@"REACHABLE!");
        [checkerLock lock];
        hasConnection = YES;
        [checkerLock signal];
        [checkerLock unlock];
    };
    reach.unreachableBlock = ^(Reachability *reach_) {
        NSLog(@"UNREACHABLE!");
        [checkerLock lock];
        hasConnection = NO;
        [checkerLock signal];
        [checkerLock unlock];
    };
    [reach startNotifier];
    [checkerLock unlock];
}

@implementation CheckNetVM

- (instancetype)init {
    self = [super init];
    if (self) {
        @synchronized ([self class]) {
            if (!checkerLock) {
                initReachability();
                checkQueue = [[NSOperationQueue alloc] init];
                checkQueue.maxConcurrentOperationCount = 1;
            }
        }
    }
    
    return self;
}

- (BOOL)checkConnection {
    NSCondition *waitLock = [[NSCondition alloc] init];
    __block BOOL check = NO;
    
    [checkQueue addOperationWithBlock:^{
        [checkerLock lock];
        while (!reach.isReachable) {
            [[AppDelegate instance] connectionError:^{
                [checkerLock lock];
                [checkerLock signal];
                [checkerLock unlock];
            }];
            [checkerLock wait];
        }
        [checkerLock unlock];
        
        [waitLock lock];
        check = YES;
        [waitLock signal];
        [waitLock unlock];
    }];
    
    [waitLock lock];
    if (!check) {
        [waitLock wait];
    }
    [waitLock unlock];
    
    return YES;
}

- (BOOL)checkConnectionWithoutPause {
    if (!hasConnection) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                        message:@"No connection =)"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    return hasConnection;
}

@end