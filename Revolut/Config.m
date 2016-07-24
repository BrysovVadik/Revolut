#import "Config.h"
#import "Transport.h"


@implementation Config {
    UIViewController *currentViewController;
}

+ (Config *)instance {
    static Config *_instance = nil;
    
    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }
    
    return _instance;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.transport = [[Transport alloc] init];
    }
    
    return self;
}

@end
