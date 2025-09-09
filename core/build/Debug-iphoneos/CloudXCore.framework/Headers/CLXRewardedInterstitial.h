//
//  CloudXRewardedInterstitial.h
//  CloudXCore
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXFullscreenAd.h>
#import <CloudXCore/CLXRewardedDelegate.h>

NS_ASSUME_NONNULL_BEGIN

/// Interface for rewarded interstitial ad in the CloudX SDK.
@protocol CLXRewardedInterstitial <CLXFullscreenAd>

/// An optional delegate that conforms to the CLXRewardedDelegate protocol. This delegate will receive events related to the rewarded interstitial ad.
@property (nonatomic, weak, nullable) id<CLXRewardedDelegate> rewardedDelegate;

@end

NS_ASSUME_NONNULL_END 