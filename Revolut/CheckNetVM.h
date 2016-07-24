#import <Foundation/Foundation.h>


@class Transport;


@interface CheckNetVM : NSObject {
    Transport *transport;
}

- (BOOL)checkConnection;

- (BOOL)checkConnectionWithoutPause;

@end