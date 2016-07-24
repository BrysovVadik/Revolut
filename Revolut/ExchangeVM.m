#import <ReactiveCocoa/EXTScope.h>
#import "ExchangeVM.h"
#import "Transport.h"
#import "Currency.h"


@implementation ExchangeVM

- (instancetype)initWithTransport:(Transport *)transport_ {
    self = [super init];
    if (self) {
        transport = transport_;
    }
    return self;
}

- (void)asyncGetUserMoney:(void (^)())completion {
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @strongify(self);
        [self getUserMoney:completion];
    });
}

- (void)getUserMoney:(void (^)())completion {
    [self checkConnection];
    
    @weakify(self);
    [transport getUserMoney:^(NSArray *data, NSError *error) {
        @strongify(self);
        if (!error && data.count) {
            self.userMoney = data;
        } else {
            self.alertInfo = @"An error occurred while getting amount of money";
        }
        completion();
    }];
}

- (void)asyncGetExchangeRates:(void (^)())completion {
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @strongify(self);
        [self getExchangeRates:completion];
    });
}

- (void)getExchangeRates:(void (^)())completion {
    [self checkConnection];
    
    @weakify(self);
    [transport getExchangeRates:^(NSMutableDictionary *data, NSError *error) {
        @strongify(self);
        if (!error && data.count) {
            self.exchangeRate = [data copy];
        } else {
            self.alertInfo = @"An error occurred while getting exchange rate";
        }
        completion();
    }];
}

- (void)asyncExchangeFrom:(Currency *)currencyFrom to:(Currency *)currencyTo withAmount:(NSInteger)amount completion:(void (^)())completion {
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @strongify(self);
        [self exchangeFrom:currencyFrom to:currencyTo withAmount:amount completion:completion];
    });
}

- (void)exchangeFrom:(Currency *)currencyFrom to:(Currency *)currencyTo withAmount:(NSInteger)amount completion:(void (^)())completion {
    [self checkConnection];
    
    for (Currency *currency in self.userMoney) {
        if ([currency.name  isEqualToString:currencyFrom.name]) {
            currency.amount -= amount;
        } else if ([currency.name  isEqualToString:currencyTo.name]) {
            currency.amount += [self calculateExchangedAmount:amount from:currencyFrom to:currencyTo];
        }
    }
}

- (BOOL)haveEnoughMoneyFor:(Currency *)currencyFrom withAmount:(CGFloat)amount {
    if (amount <= currencyFrom.amount) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)moneyCurrencyFrom:(Currency *)currencyFrom NotEqualTo:(Currency *)currencyTo {
    if ([currencyFrom.name isEqualToString:currencyTo.name]) {
        return NO;
    } else {
        return YES;
    }
}

- (CGFloat)calculateRateFrom:(Currency *)currencyFrom to:(Currency *)currencyTo {
    if ([currencyFrom.name isEqualToString:@"USD"]) {
        return [self.exchangeRate[currencyTo.name] floatValue];
    } else {
        return [self.exchangeRate[currencyTo.name] floatValue] / [self.exchangeRate[currencyFrom.name] floatValue];
    }
}

- (CGFloat)calculateExchangedAmount:(CGFloat)amount from:(Currency *)currencyFrom to:(Currency *)currencyTo {
    if ([currencyFrom.name isEqualToString:@"USD"]) {
        return amount * [self.exchangeRate[currencyTo.name] floatValue];
    } else {
        return amount / [self.exchangeRate[currencyFrom.name] floatValue] * [self.exchangeRate[currencyTo.name] floatValue];
    }
}

@end
