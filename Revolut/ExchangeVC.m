#import "ExchangeVC.h"
#import "CollectionCell.h"
#import "Currency.h"
#import "Config.h"
#import "Transport.h"
#import "ExchangeVM.h"
#import <ReactiveCocoa/EXTScope.h>
#import <ReactiveCocoa/RACScheduler.h>
#import <ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACKVOChannel.h>
#import "MBProgressHUD.h"


@interface ExchangeVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *buttonExchangeRate;
@property (weak, nonatomic) IBOutlet UIButton *buttonExchange;

@property (weak, nonatomic) IBOutlet UIPageControl *pageControlExchangeFrom;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionExchangeFrom;

@property (weak, nonatomic) IBOutlet UIPageControl *pageControlExchangeTo;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionExchangeTo;

@property (weak, nonatomic) IBOutlet UITextField *textFieldInput;
@property (weak, nonatomic) IBOutlet UIView *viewBody;

@end


@implementation ExchangeVC {
    NSArray *collectionDataExchangeFrom;
    NSArray *collectionDataExchangeTo;
    NSInteger currentIndexCellExchangeFrom;
    NSInteger currentIndexCellExchangeTo;
    
    NSString *userInput;
    
    ExchangeVM *viewModel;
    RACChannelTerminal *alertTerm;
    RACChannelTerminal *userMoneyTerm;
    NSArray *userMoney;
    RACChannelTerminal *exchangeRatesTerm;
    NSDictionary *exchangeRate;
    
    NSTimer *requestTimer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    userInput = @"";
    currentIndexCellExchangeFrom = 0;
    currentIndexCellExchangeTo = 0;
    
    self.buttonExchangeRate.layer.cornerRadius = 10;
    self.buttonExchangeRate.layer.borderWidth = 1;
    self.buttonExchangeRate.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.4].CGColor;
    
    [self.textFieldInput addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self bindVM];
    
    [MBProgressHUD showHUDAddedTo:self.viewBody animated:YES];
    [viewModel asyncGetUserMoney:^{
        [viewModel asyncGetExchangeRates:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.viewBody animated:YES];
            });
        }];
    }];
    
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        @strongify(self);
        self->requestTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(getExchangeRates) userInfo:nil repeats:YES];
    });
    
    [self.textFieldInput becomeFirstResponder];
    [self setupExchangeRate:[NSString stringWithFormat:@"$%d = €%.4f", 1, 1.0000]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self unbindVM];
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
    
    [viewModel asyncExchangeFrom:currencyFrom to:currencyTo withAmount:[userInput floatValue] completion:^{
    }];
    
    [self setupCollectionsDataForInfiniteScrolling];
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
        
        if (!userInput.length || [viewModel haveEnoughMoneyFor:currency withAmount:[userInput floatValue]]) {
            cell.labelMoneyAmount.textColor = [UIColor whiteColor];
        } else {
            cell.labelMoneyAmount.textColor = [UIColor redColor];
        }
        
    } else if ([collectionView isEqual:self.collectionExchangeTo]) {
        cell = (CollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CellTo" forIndexPath:indexPath];
        currency= collectionDataExchangeTo[indexPath.row];
        Currency *currencyFrom = collectionDataExchangeFrom[currentIndexCellExchangeFrom];
        
        if (userInput.length) {
            CGFloat exchangedAmount = [viewModel calculateExchangedAmount:[userInput floatValue] from:currencyFrom to:currency];
            cell.labelExchangedMoney.text = [NSString stringWithFormat:@"+%.2f", exchangedAmount];
        } else {
            cell.labelExchangedMoney.text = @"";
        }
        
        if ([viewModel moneyCurrencyFrom:currencyFrom NotEqualTo:currency] && exchangeRate) {
            CGFloat exchangedRate = [viewModel calculateRateFrom:currencyFrom to:currency];
            cell.labelExchangeRate.text = [NSString stringWithFormat:@"%@%d = %@%.2f", currencyFrom.symbol, 1, currency.symbol, exchangedRate];
            [self setupExchangeRate:[NSString stringWithFormat:@"%@%d = %@%.4f", currencyFrom.symbol, 1, currency.symbol, exchangedRate]];
        } else {
            cell.labelExchangeRate.text = @"";
            NSString *exchangeRateString = [NSString stringWithFormat:@"%@%d = %@%.4f", currencyFrom.symbol, 1, currency.symbol, 1.0000];
            [self setupExchangeRate:exchangeRateString];
        }
    }
    
    cell.labelCurrency.text = currency.name;
    cell.labelMoneyAmount.text = [NSString stringWithFormat:@"You have %@%.2f", currency.symbol, currency.amount];
    
    return cell;
}

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
    Currency *currencyFrom = collectionDataExchangeFrom[currentIndexCellExchangeFrom];
    Currency *currencyTo = collectionDataExchangeTo[currentIndexCellExchangeTo];
    if (exchangeRate && exchangeRate.count && [viewModel moneyCurrencyFrom:currencyFrom NotEqualTo:currencyTo]) {
        userInput = textField.text;
        if (userInput.length &&
            [viewModel haveEnoughMoneyFor:currencyFrom withAmount:[userInput floatValue]] &&
            [viewModel moneyCurrencyFrom:currencyFrom NotEqualTo:currencyTo]) {
            self.buttonExchange.enabled = YES;
        } else {
            self.buttonExchange.enabled = NO;
        }
        
        [self reloadData];
    }
}

- (void)setupExchangeRate:(NSString *)rateString {
    UIFont *bigFont = [UIFont systemFontOfSize:14.0];
    NSDictionary *bigDict = [NSDictionary dictionaryWithObject: bigFont forKey:NSFontAttributeName];
    NSMutableAttributedString *atrString = [[NSMutableAttributedString alloc] initWithString:rateString attributes: bigDict];
    [atrString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:10.0] range:(NSMakeRange(rateString.length - 2, 2))];
    [atrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:(NSMakeRange(0, rateString.length))];
    
    [self.buttonExchangeRate setAttributedTitle:atrString forState:UIControlStateNormal];
}

- (void)clearUserInput {
    userInput = @"";
    self.textFieldInput.text = userInput;
    [self reloadData];
    self.buttonExchange.enabled = NO;
}

- (void)reloadData {
    [self.collectionExchangeFrom reloadData];
    [self.collectionExchangeTo reloadData];
}

- (void)bindVM {
    Config *config = [Config instance];
    viewModel = [[ExchangeVM alloc] initWithTransport:config.transport];
    
    @weakify(self);
    userMoneyTerm = RACChannelTo(viewModel, userMoney);
    [[[userMoneyTerm skip:1] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSArray *x) {
        @strongify(self);
        if (![x count]) {
            self->userMoney = @[];
        } else {
            self->userMoney = x;
        }
    }];
    
    exchangeRatesTerm = RACChannelTo(viewModel, exchangeRate);
    [[[exchangeRatesTerm skip:1] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDictionary *x) {
        @strongify(self);
        if (![x count]) {
            self->exchangeRate = @{};
        } else {
            self->exchangeRate = x;
        }
        [self setupCollectionsDataForInfiniteScrolling];
    }];
    
    alertTerm = RACChannelTo(viewModel, alertInfo);
    [[alertTerm deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSString *message) {
        if ([message length]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)unbindVM {
    [alertTerm sendCompleted];
    [userMoneyTerm sendCompleted];
    [exchangeRatesTerm sendCompleted];
}

- (void)getExchangeRates {
    [viewModel asyncGetExchangeRates:^{
    }];
}

- (void)setupCollectionsDataForInfiniteScrolling {
    NSArray *originalArrayFrom = [userMoney copy];
    
    id firstItemFrom = originalArrayFrom[0];
    id lastItemFrom = [originalArrayFrom lastObject];
    
    NSMutableArray *workingArrayFrom = [originalArrayFrom mutableCopy];
    [workingArrayFrom insertObject:lastItemFrom atIndex:0];
    [workingArrayFrom addObject:firstItemFrom];
    
    collectionDataExchangeFrom = [NSMutableArray arrayWithArray:workingArrayFrom];
    
    
    NSMutableArray *originalArrayTo = [userMoney mutableCopy];
    [originalArrayTo addObject:originalArrayTo[0]];
    [originalArrayTo removeObjectAtIndex:0];
    
    id firstItemTo = originalArrayTo[0];
    id lastItemTo = [originalArrayTo lastObject];
    
    [originalArrayTo insertObject:lastItemTo atIndex:0];
    [originalArrayTo addObject:firstItemTo];
    
    collectionDataExchangeTo = [NSMutableArray arrayWithArray:originalArrayTo];
    
    [self reloadData];
}

@end
