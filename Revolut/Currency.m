//
//  Currency.m
//  Revolut
//
//  Created by Vadim on 21/07/16.
//  Copyright © 2016 Brysov Corp. All rights reserved.
//

#import "Currency.h"

@implementation Currency

- (id)initWithName:(NSString *)name_ amount:(CGFloat )amount_ symbol:(NSString *)symbol_ {
    self = [super init];
    if (self) {
        self.name = name_;
        self.amount = amount_;
        self.symbol = symbol_;
    }
    return self;
}

@end
