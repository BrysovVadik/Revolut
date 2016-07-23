//
//  ViewController.m
//  Revolut
//
//  Created by Vadim on 19/07/16.
//  Copyright © 2016 Brysov Corp. All rights reserved.
//

#import "ViewController.h"
#import "CollectionCell.h"
#import "AFHTTPRequestOperationManager.h"
#import "Currency.h"

//$€£

@interface ViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *buttonExchangeRate;
@property (weak, nonatomic) IBOutlet UIButton *buttonExchange;

@property (weak, nonatomic) IBOutlet UIPageControl *pageControlExchangeFrom;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionExchangeFrom;

@property (weak, nonatomic) IBOutlet UIPageControl *pageControlExchangeTo;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionExchangeTo;

@property (weak, nonatomic) IBOutlet UITextField *textFieldInput;

@end

@implementation ViewController {
    NSMutableArray *collectionDataExchangeFrom;
    NSArray *collectionDataExchangeTo;
    
    NSInteger currentIndexCellExchangeFrom;
    NSInteger currentIndexCellExchangeTo;
    
    NSArray *userMoney;
    NSDictionary *exchangeRate;
    
    NSString *userInput;
    CGFloat exchangedAmount;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    userInput = @"";
    
    Currency *userUSD = [[Currency alloc] initWithName:@"USD" amount:100.0 symbol:@"$"];
    Currency *userEUR = [[Currency alloc] initWithName:@"EUR" amount:100.0 symbol:@"€"];
    Currency *userGBP = [[Currency alloc] initWithName:@"GBP" amount:100.0 symbol:@"£"];
    userMoney = @[userUSD, userEUR, userGBP];
    
    currentIndexCellExchangeFrom = 0;
    currentIndexCellExchangeTo = 0;
    
    [self setupDataForCollectionExchangeFrom];
    //    [self setupDataForCollectionExchangeTo];
    
    self.buttonExchangeRate.layer.cornerRadius = 10;
    self.buttonExchangeRate.layer.borderWidth = 1;
    self.buttonExchangeRate.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.4].CGColor;
    
    [self.textFieldInput addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.textFieldInput becomeFirstResponder];
    [self setupExchangeRate:[NSString stringWithFormat:@"$%d = €%.2f", 1, 1.0000]];
    
    [self getUserData:^(NSDictionary *data, NSError *error) {
        if (!error && data) {
            exchangeRate = data;
        }
    }];
}

- (void)setupExchangeRate:(NSString *)rateString {
    UIFont *bigFont = [UIFont systemFontOfSize:14.0];
    NSDictionary *bigDict = [NSDictionary dictionaryWithObject: bigFont forKey:NSFontAttributeName];
    NSMutableAttributedString *atrString = [[NSMutableAttributedString alloc] initWithString:rateString attributes: bigDict];
    [atrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10.0] range:(NSMakeRange(rateString.length - 2, 2))];
    [atrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:(NSMakeRange(0, rateString.length))];
    
    [self.buttonExchangeRate setAttributedTitle:atrString forState:UIControlStateNormal];
}

- (void)getUserData:(void (^)(NSMutableDictionary *data, NSError *error))completion {
    AFHTTPRequestOperationManager *restManager = [AFHTTPRequestOperationManager manager];
    restManager.responseSerializer = [AFJSONResponseSerializer serializer];
    restManager.requestSerializer = [AFJSONRequestSerializer serializer];
    restManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    restManager.requestSerializer.timeoutInterval = 30;
    
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

- (IBAction)cancelTap:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"Other screens of the app are in development =)"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)exchangeTap:(id)sender {
    Currency *currencyFrom = collectionDataExchangeFrom[currentIndexCellExchangeFrom];
    Currency *currencyTo = collectionDataExchangeTo[currentIndexCellExchangeTo];
    
    for (Currency *currency in userMoney) {
        if ([currency.name  isEqualToString:currencyFrom.name]) {
            currency.amount -= [userInput integerValue];
        } else if ([currency.name  isEqualToString:currencyTo.name]) {
            currency.amount += exchangedAmount;
        }
    }
    
    [self setupDataForCollectionExchangeFrom];
    [self clearUserInput];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    CGSize calculateSize = CGSizeMake(collectionView.frame.size.width, collectionView.frame.size.height);
    return calculateSize;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([collectionView isEqual:self.collectionExchangeFrom]) {
        return collectionDataExchangeFrom.count;
    } else if ([collectionView isEqual:self.collectionExchangeTo]){
        return collectionDataExchangeFrom.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionCell *cell;
    Currency *currency;
    
    if ([collectionView isEqual:self.collectionExchangeFrom]) {
        cell = (CollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CellFrom" forIndexPath:indexPath];
        currency = collectionDataExchangeFrom[indexPath.row];
        
        if (userInput.length) {
            cell.labelMoneyForExchange.text = [@"-" stringByAppendingString:userInput];
        } else {
            cell.labelMoneyForExchange.text = @"";
        }
        
        if ([self haveEnoughMoney] || !userInput.length) {
            cell.labelMoneyAmount.textColor = [UIColor whiteColor];
        } else {
            cell.labelMoneyAmount.textColor = [UIColor redColor];
        }
        
    } else if ([collectionView isEqual:self.collectionExchangeTo]) {
        cell = (CollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CellTo" forIndexPath:indexPath];
        currency= collectionDataExchangeTo[indexPath.row];
        Currency *currencyFrom = collectionDataExchangeFrom[currentIndexCellExchangeFrom];
        
        if (userInput.length) {
            exchangedAmount = [self calculateAmountFrom:currencyFrom to:currency];
            cell.labelExchangedMoney.text = [NSString stringWithFormat:@"+%.2f", exchangedAmount];
        } else {
            cell.labelExchangedMoney.text = @"";
        }
        
        if ([self moneyCurrencyNotEqual] && exchangeRate) {
            CGFloat exchangedRate = [self calculateRateFrom:currencyFrom to:currency];
            cell.labelExchangeRate.text = [NSString stringWithFormat:@"%@%d = %@%.2f", currencyFrom.symbol, 1, currency.symbol, exchangedRate];
            [self setupExchangeRate:[NSString stringWithFormat:@"%@%d = %@%.4f", currencyFrom.symbol, 1, currency.symbol, exchangedRate]];
        } else {
            cell.labelExchangeRate.text = @"";
            NSString *exchangeRateString = [NSString stringWithFormat:@"%@%d = %@%.2f", currencyFrom.symbol, 1, currency.symbol, 1.0000];
            [self setupExchangeRate:exchangeRateString];
        }
    }
    
    cell.labelCurrency.text = currency.name;
    cell.labelMoneyAmount.text = [NSString stringWithFormat:@"You have %@%.2f", currency.symbol, currency.amount];
    
    return cell;
}

- (CGFloat)calculateRateFrom:(Currency *)currencyFrom to:(Currency *)currencyTo {
    if ([currencyFrom.name isEqualToString:@"USD"]) {
        return [exchangeRate[currencyTo.name] floatValue];
    } else {
        return [exchangeRate[currencyTo.name] floatValue] / [exchangeRate[currencyFrom.name] floatValue];
    }
}

- (CGFloat)calculateAmountFrom:(Currency *)currencyFrom to:(Currency *)currencyTo {
    if ([currencyFrom.name isEqualToString:@"USD"]) {
        return [userInput floatValue] * [exchangeRate[currencyTo.name] floatValue];
    } else {
        return [userInput floatValue] / [exchangeRate[currencyFrom.name] floatValue] * [exchangeRate[currencyTo.name] floatValue];
    }
}

- (void)setupDataForCollectionExchangeFrom {
    NSArray *originalArray = [userMoney copy];
    
    id firstItem = originalArray[0];
    id lastItem = [originalArray lastObject];
    
    NSMutableArray *workingArray = [originalArray mutableCopy];
    [workingArray insertObject:lastItem atIndex:0];
    [workingArray addObject:firstItem];
    
    collectionDataExchangeFrom = [NSMutableArray arrayWithArray:workingArray];
    collectionDataExchangeTo = [NSMutableArray arrayWithArray:workingArray];
    
    [self.collectionExchangeFrom reloadData];
    [self.collectionExchangeTo reloadData];
}

//- (void)setupDataForCollectionExchangeTo {
//    NSArray *originalArray = [userMoney copy];
//
//    id firstItem = originalArray[0];
//    id lastItem = [originalArray lastObject];
//
//    NSMutableArray *workingArray = [originalArray mutableCopy];
//    [workingArray insertObject:lastItem atIndex:0];
//    [workingArray addObject:firstItem];
//
//    collectionDataExchangeTo = [NSArray arrayWithArray:workingArray];
//}

- (void)scrollViewDidEndDecelerating:(UICollectionView *)collectionView {
    NSArray *collectionData = [NSArray new];
    UIPageControl *pageControl = [UIPageControl new];
    
    CGFloat pageWidth = collectionView.frame.size.width;
    NSInteger page = (NSInteger) (floor((collectionView.contentOffset.x - pageWidth / 2) / pageWidth) + 1);
    
    if ([collectionView isEqual:self.collectionExchangeFrom]) {
        collectionData = collectionDataExchangeFrom;
        pageControl = self.pageControlExchangeFrom;
        currentIndexCellExchangeFrom = page;
    } else if ([collectionView isEqual:self.collectionExchangeTo]){
        collectionData = collectionDataExchangeTo;
        pageControl = self.pageControlExchangeTo;
        currentIndexCellExchangeTo = page;
    }
    
    if (page == (collectionData.count - 2)) {
        page = 0;
    } else if (page == (collectionData.count - 1)) {
        page = 1;
    }
    NSLog(@"Scrolling - You are now on page %i", page);
    pageControl.currentPage = page;
    
    // Calculate where the collection view should be at the right-hand end item
    float contentOffsetWhenFullyScrolledRight = collectionView.frame.size.width * ([collectionData count] -1);
    if (collectionView.contentOffset.x == contentOffsetWhenFullyScrolledRight) {
        // user is scrolling to the right from the last item to the 'fake' item 1.
        // reposition offset to show the 'real' item 1 at the left-hand end of the collection view
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
        [collectionView scrollToItemAtIndexPath:newIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    } else if (collectionView.contentOffset.x == 0)  {
        // user is scrolling to the left from the first item to the fake 'item N'.
        // reposition offset to show the 'real' item N at the right end end of the collection view
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:([collectionData count] -2) inSection:0];
        [collectionView scrollToItemAtIndexPath:newIndexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
    }
    
    [self clearUserInput];
}

- (void)textFieldDidChange:(UITextField *)textField {
    if (exchangeRate && exchangeRate.count && [self moneyCurrencyNotEqual]) {
        userInput = textField.text;
        if (userInput.length && [self haveEnoughMoney] && [self moneyCurrencyNotEqual]) {
            self.buttonExchange.enabled = YES;
        } else {
            self.buttonExchange.enabled = NO;
        }
        //    Currency *currencyFrom = collectionDataExchangeFrom[currentIndexCellExchangeFrom];
        
        [self.collectionExchangeFrom reloadData];
        [self.collectionExchangeTo reloadData];
        
        //         NSIndexPath *currentIndexPathFrom = [[NSIndexPath alloc] initWithIndex:currentIndexCellExchangeFrom];
        //        [self.collectionExchangeFrom reloadItemsAtIndexPaths:@[currentIndexPathFrom]];
        //        CollectionCell *currentCellFrom  = (CollectionCell *)[self.collectionExchangeFrom cellForItemAtIndexPath:currentIndexPathFrom];
    }
}

- (void)clearUserInput {
    userInput = @"";
    self.textFieldInput.text = userInput;
    [self.collectionExchangeFrom reloadData];
    [self.collectionExchangeTo reloadData];
    self.buttonExchange.enabled = NO;
}

- (BOOL)haveEnoughMoney {
    Currency *currencyFrom = collectionDataExchangeFrom[currentIndexCellExchangeFrom];
    if ([userInput integerValue] <= currencyFrom.amount) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)moneyCurrencyNotEqual {
    Currency *currencyFrom = collectionDataExchangeFrom[currentIndexCellExchangeFrom];
    Currency *currencyTo = collectionDataExchangeTo[currentIndexCellExchangeTo];
    if ([currencyFrom.name isEqualToString:currencyTo.name]) {
        return NO;
    } else {
        return YES;
    }
}

@end
