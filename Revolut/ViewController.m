//
//  ViewController.m
//  Revolut
//
//  Created by Vadim on 19/07/16.
//  Copyright © 2016 Brysov Corp. All rights reserved.
//

#import "ViewController.h"
#import "CollectionCell.h"

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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.buttonExchangeRate.layer.cornerRadius = 10;
    self.buttonExchangeRate.layer.borderWidth = 1;
    self.buttonExchangeRate.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.4].CGColor;
    
    [self setupDataForCollectionExchangeFrom];
    [self setupDataForCollectionExchangeTo];
    
    [self.textFieldInput addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.textFieldInput becomeFirstResponder];
}

- (IBAction)cancelTap:(id)sender {
    
}

- (IBAction)exchangeTap:(id)sender {
    
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
    
    if ([collectionView isEqual:self.collectionExchangeFrom]) {
        cell = (CollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CellFrom" forIndexPath:indexPath];
        cell.labelCurrency.text = collectionDataExchangeFrom[indexPath.row];
    } else if ([collectionView isEqual:self.collectionExchangeTo]) {
        cell = (CollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CellTo" forIndexPath:indexPath];
        cell.labelCurrency.text = collectionDataExchangeTo[indexPath.row];
    }
    
    return cell;
}

- (void)setupDataForCollectionExchangeFrom {
    NSArray *originalArray = @[@"EUR", @"GBP", @"USD"];

    id firstItem = originalArray[0];
    id lastItem = [originalArray lastObject];
    
    NSMutableArray *workingArray = [originalArray mutableCopy];
    [workingArray insertObject:lastItem atIndex:0];
    [workingArray addObject:firstItem];
    
    collectionDataExchangeFrom = [NSMutableArray arrayWithArray:workingArray];
}

- (void)setupDataForCollectionExchangeTo {
    NSArray *originalArray = @[@"USD", @"EUR", @"GBP"];
    
    id firstItem = originalArray[0];
    id lastItem = [originalArray lastObject];
    
    NSMutableArray *workingArray = [originalArray mutableCopy];
    [workingArray insertObject:lastItem atIndex:0];
    [workingArray addObject:firstItem];
    
    collectionDataExchangeTo = [NSArray arrayWithArray:workingArray];
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
}

- (void)textFieldDidChange:(UITextField *)theTextField {
    NSString *userInput = theTextField.text;
    collectionDataExchangeFrom[0] = userInput;
    
    NSIndexPath *currentIndexPath = [[NSIndexPath alloc] initWithIndex:currentIndexCellExchangeFrom];
    CollectionCell *currentCell  = (CollectionCell *)[self.collectionExchangeFrom cellForItemAtIndexPath:currentIndexPath];
    
    [self.collectionExchangeFrom reloadItemsAtIndexPaths:@[currentIndexPath]];
}

@end
