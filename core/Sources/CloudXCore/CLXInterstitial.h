/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CloudXInterstitial.h
 * @brief Interstitial ad protocol
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXFullscreenAd.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudXInterstitial is an interface of interstitial ad in the CloudX SDK. 
 * It inherits from the CloudXAd protocol.
 */
@protocol CLXInterstitial <CLXFullscreenAd>

/**
 * An optional delegate that conforms to the CLXInterstitialDelegate protocol. 
 * This delegate will receive events related to the interstitial ad.
 */
@property (nonatomic, weak, nullable) id<CLXInterstitialDelegate> interstitialDelegate;

@end

NS_ASSUME_NONNULL_END 