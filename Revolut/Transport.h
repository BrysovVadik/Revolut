#import <UIKit/UIKit.h>


@interface Transport : NSObject

- (void)getExchangeRates:(void (^)(NSMutableDictionary *data, NSError *error))completion;

- (void)getUserMoney:(void (^)(NSArray *data, NSError *error))completion;

@end
