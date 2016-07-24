#import <UIKit/UIKit.h>


@interface CollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelCurrency;
@property (weak, nonatomic) IBOutlet UILabel *labelMoneyAmount;
@property (weak, nonatomic) IBOutlet UILabel *labelMoneyForExchange;
@property (weak, nonatomic) IBOutlet UILabel *labelExchangedMoney;
@property (weak, nonatomic) IBOutlet UILabel *labelExchangeRate;

@end
