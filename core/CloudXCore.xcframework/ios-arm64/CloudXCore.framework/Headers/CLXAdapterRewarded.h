/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterRewarded.h
 * @brief Abstract base class for rewarded adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXAdapterLoadParams.h>
#import <CloudXCore/CLXAdapterShowParams.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>

@protocol CLXAdapterRewardedDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for rewarded adapters.
 *
 * Subclass per ad network. Required overrides: @c -load,
 * @c -showFromViewController:, @c -destroy. Subclasses update @c _isReady or
 * override @c -isReady to report SDK readiness.
 * The @c delegate retain-cycle break must happen in @c -destroy.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterRewarded : NSObject <CLXDestroyable> {
@protected
    id<CLXAdapterRewardedDelegate> _Nullable _delegate;
    BOOL _isReady;
}

/// Delegate for the adapter, used to notify about ad events.
/// Strong to keep the callback chain alive through the ad lifecycle.
/// Cycle is broken in @c -destroy.
@property (nonatomic, strong, nullable) id<CLXAdapterRewardedDelegate> delegate;

/// Whether the ad is ready to be shown.
@property (nonatomic, assign, readonly) BOOL isReady;

/// Loads the rewarded adapter. Subclass MUST override.
- (void)loadWithParams:(CLXAdapterLoadParams *)loadParams;

/// Shows the rewarded adapter. Subclass MUST override.
- (void)showWithParams:(CLXAdapterShowParams *)showParams;

/// Destroys the adapter and breaks the retain cycle by nilling the delegate.
/// Subclass MUST override.
- (void)destroy;

@end

/// Delegate for the rewarded adapter.
@protocol CLXAdapterRewardedDelegate <NSObject>

/// Called when the adapter has loaded the rewarded.
/// @param extras Additional adapter-provided callback details.
- (void)didLoadRewarded:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter failed to load the rewarded.
/// @param error The error that caused the failure.
/// @param extras Additional adapter-provided callback details.
- (void)didFailToLoadRewardedWithError:(NSError *)error extras:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter has shown the rewarded.
/// @param extras Additional adapter-provided callback details.
- (void)didDisplayRewarded:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter has tracked impression.
/// @param extras Additional adapter-provided callback details.
- (void)didTrackRewardedImpression:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter has closed the rewarded.
/// @param extras Additional adapter-provided callback details.
- (void)didHideRewarded:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter failed to show the rewarded.
/// @param error The error that caused the failure.
/// @param extras Additional adapter-provided callback details.
- (void)didFailToDisplayRewardedWithError:(NSError *)error extras:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter has tracked click.
/// @param extras Additional adapter-provided callback details.
- (void)didClickRewarded:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter expired the rewarded.
/// @param extras Additional adapter-provided callback details.
- (void)didExpireRewarded:(NSDictionary<NSString *, id> *)extras;

/// Called when the adapter rewarded the user with reward details.
/// @param amount The reward amount from the ad network (0 if not provided).
/// @param label The reward label/currency from the ad network (nil if not provided).
/// @param extras Additional adapter-provided callback details.
- (void)didRewardUserWithAmount:(NSInteger)amount label:(nullable NSString *)label extras:(NSDictionary<NSString *, id> *)extras;

@end

NS_ASSUME_NONNULL_END
