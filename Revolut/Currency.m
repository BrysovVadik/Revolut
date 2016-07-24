#import "Currency.h"


@implementation Currency

- (id)initWithName:(NSString *)name_ amount:(CGFloat )amount_ symbol:(NSString *)symbol_ {
    self = [super init];
    if (self) {
        self.name = name_;
        self.amount = amount_;
        self.symbol = symbol_;
    }
    return self;
}

@end
