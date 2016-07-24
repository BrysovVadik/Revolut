#import "Transport.h"
#import <AFNetworking/AFNetworking.h>
#import "Currency.h"


@implementation Transport {
    AFHTTPRequestOperationManager *restManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        restManager = [AFHTTPRequestOperationManager manager];
        restManager.responseSerializer = [AFJSONResponseSerializer serializer];
        restManager.requestSerializer = [AFJSONRequestSerializer serializer];
        restManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        restManager.requestSerializer.timeoutInterval = 30;
    }
    return self;
}

- (void)getExchangeRates:(void (^)(NSMutableDictionary *, NSError *))completion {
//    [restManager GET:@"https://api.fixer.io/latest?symbols=USD,GBP"
//    [restManager GET:@"https://openexchangerates.org/api/latest.json?app_id=f34802952217477ba958ed93c39d5d2c"
    [restManager GET:@"http://www.apilayer.net/api/live?access_key=fa11b482e47b901b28ced28cbcc0af03&currencies=EUR,GBP"
          parameters:@{}
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 NSDictionary *resp = (NSDictionary *) responseObject;
                 NSMutableDictionary *currencies = [@{} mutableCopy];
                 
                 if (resp[@"source"]) {
                     NSString *base = resp[@"source"];
                     currencies[base] = @(1.0);
                     
                     if ([resp[@"quotes"] count]) {
                         for (NSString *key in resp[@"quotes"]) {
                             NSNumber *value = resp[@"quotes"][key];
                             NSString *cutKey = [key substringFromIndex:base.length];
                             currencies[cutKey] = value;
                         }
                     }
                 }
                 
                 completion(currencies, nil);
             }
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 completion(nil, error);
             }];
}

- (void)getUserMoney:(void (^)(NSArray *, NSError *))completion {
    //Test data
    Currency *userUSD = [[Currency alloc] initWithName:@"USD" amount:100.0 symbol:@"$"];
    Currency *userEUR = [[Currency alloc] initWithName:@"EUR" amount:100.0 symbol:@"€"];
    Currency *userGBP = [[Currency alloc] initWithName:@"GBP" amount:100.0 symbol:@"£"];
    completion(@[userUSD, userEUR, userGBP], nil);
}

@end