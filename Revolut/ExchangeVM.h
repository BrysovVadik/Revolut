#import <UIKit/UIKit.h>
#import "CheckNetVM.h"


@class Transport;
@class Currency;


@interface ExchangeVM : CheckNetVM

@property(nonatomic) NSString *alertInfo;
@property(nonatomic) NSArray *userMoney;
@property(nonatomic) NSDictionary *exchangeRate;

- (instancetype)initWithTransport:(Transport *)transport;

- (void)asyncGetUserMoney:(void (^)())completion;

- (void)asyncGetExchangeRates:(void (^)())completion;

- (void)asyncExchangeFrom:(Currency *)currencyFrom to:(Currency *)currencyTo withAmount:(NSInteger)amount completion:(void (^)())completion;

- (BOOL)haveEnoughMoneyFor:(Currency *)currencyFrom withAmount:(CGFloat)amount;

- (BOOL)moneyCurrencyFrom:(Currency *)currencyFrom NotEqualTo:(Currency *)currencyTo;

- (CGFloat)calculateRateFrom:(Currency *)currencyFrom to:(Currency *)currencyTo;

- (CGFloat)calculateExchangedAmount:(CGFloat)amount from:(Currency *)currencyFrom to:(Currency *)currencyTo;

@end
