//
//  CollectionCell.h
//  Revolut
//
//  Created by Vadim on 19/07/16.
//  Copyright © 2016 Brysov Corp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *labelCurrency;
@property (weak, nonatomic) IBOutlet UILabel *labelMoneyAmount;
@property (weak, nonatomic) IBOutlet UILabel *labelMoneyForExchange;
@property (weak, nonatomic) IBOutlet UILabel *labelExchangedMoney;
@property (weak, nonatomic) IBOutlet UILabel *labelExchangeRate;

@end
