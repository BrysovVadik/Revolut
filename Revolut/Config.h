#import <UIKit/UIKit.h>


@class Transport;

@interface Config : NSObject

+ (Config *)instance;

@property(nonatomic) Transport *transport;

@end
