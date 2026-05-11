/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXReward.h
 * @brief Reward data object representing a reward granted to the user
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXReward represents a reward given to the user after watching a rewarded ad.
 * Similar to MAReward in AppLovin MAX SDK.
 */
CLX_PUBLIC
@interface CLXReward : NSObject

/**
 * The default label used when no label is specified
 */
@property (class, nonatomic, copy, readonly) NSString *defaultLabel;

/**
 * The default amount used when no amount is specified
 */
@property (class, nonatomic, assign, readonly) NSInteger defaultAmount;

/**
 * The reward label/currency (e.g., "coins", "gems", "Golden Coins")
 */
@property (nonatomic, copy, readonly) NSString *label;

/**
 * The reward amount (e.g., 100, 1000)
 */
@property (nonatomic, assign, readonly) NSInteger amount;

/**
 * Creates a reward with default values
 */
+ (instancetype)reward;

/**
 * Creates a reward with specified amount and label
 * @param amount The reward amount
 * @param label The reward label/currency
 */
+ (instancetype)rewardWithAmount:(NSInteger)amount label:(NSString *)label;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
