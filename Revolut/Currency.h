#import <UIKit/UIKit.h>


@interface Currency : NSObject

@property NSString *name;
@property NSString *symbol;
@property CGFloat amount;

- (id)initWithName:(NSString *)name_ amount:(CGFloat)amount_ symbol:(NSString *)symbol_;

@end
