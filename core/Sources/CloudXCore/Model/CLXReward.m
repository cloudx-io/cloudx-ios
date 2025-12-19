/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXReward.m
 * @brief Implementation of reward data object
 */

#import <CloudXCore/CLXReward.h>

@interface CLXReward ()
@property (nonatomic, copy, readwrite) NSString *label;
@property (nonatomic, assign, readwrite) NSInteger amount;
@end

@implementation CLXReward

+ (NSString *)defaultLabel {
    return @"Reward";
}

+ (NSInteger)defaultAmount {
    return 1;
}

+ (instancetype)reward {
    return [self rewardWithAmount:[self defaultAmount] label:[self defaultLabel]];
}

+ (instancetype)rewardWithAmount:(NSInteger)amount label:(NSString *)label {
    CLXReward *reward = [[CLXReward alloc] initPrivate];
    reward.amount = amount;
    reward.label = label ?: [CLXReward defaultLabel];
    return reward;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _amount = [CLXReward defaultAmount];
        _label = [CLXReward defaultLabel];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"CLXReward(amount=%ld, label=%@)", (long)self.amount, self.label];
}

@end
