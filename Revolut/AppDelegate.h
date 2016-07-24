#import <UIKit/UIKit.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate>

+ (instancetype)instance;

@property (strong, nonatomic) UIWindow *window;

- (void)connectionError:(void (^)())completion;

@end

