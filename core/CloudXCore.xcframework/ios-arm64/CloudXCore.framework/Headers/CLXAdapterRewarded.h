/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterRewarded.h
 * @brief Abstract base class for rewarded adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>

@protocol CLXAdapterRewardedDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for rewarded adapters.
 *
 * Subclass per ad network. Required overrides: @c -load,
 * @c -showFromViewController:, @c -destroy. Subclasses populate @c _bidID and
 * either update @c _isReady or override @c -isReady to report SDK readiness.
 * The @c delegate retain-cycle break must happen in @c -destroy.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterRewarded : NSObject <CLXDestroyable> {
@protected
    id<CLXAdapterRewardedDelegate> _Nullable _delegate;
    NSString *_bidID;
    BOOL _isReady;
}

/// Delegate for the adapter, used to notify about ad events.
/// Strong to keep the callback chain alive through the ad lifecycle.
/// Cycle is broken in @c -destroy.
@property (nonatomic, strong, nullable) id<CLXAdapterRewardedDelegate> delegate;

/// Bid id from bid response.
@property (nonatomic, copy, readonly) NSString *bidID;

/// Whether the ad is ready to be shown.
@property (nonatomic, assign, readonly) BOOL isReady;

/// Loads the rewarded adapter. Subclass MUST override.
- (void)load;

/// Shows the rewarded adapter. Subclass MUST override.
/// @param viewController View controller from which the rewarded ad is shown.
- (void)showFromViewController:(UIViewController *)viewController;

/// Destroys the adapter and breaks the retain cycle by nilling the delegate.
/// Subclass MUST override.
- (void)destroy;

@end

/// Delegate for the rewarded adapter.
@protocol CLXAdapterRewardedDelegate <NSObject>

/// Called when the adapter has loaded the rewarded.
/// @param rewarded The rewarded adapter that was loaded.
- (void)didLoadWithRewarded:(CLXAdapterRewarded *)rewarded;

/// Called when the adapter failed to load the rewarded.
/// @param rewarded The rewarded adapter that failed to load.
/// @param error The error that caused the failure.
- (void)didFailToLoadWithRewarded:(CLXAdapterRewarded *)rewarded error:(NSError *)error;

/// Called when the adapter has shown the rewarded.
/// @param rewarded The rewarded adapter that was shown.
- (void)didShowWithRewarded:(CLXAdapterRewarded *)rewarded;

/// Called when the adapter has tracked impression.
/// @param rewarded The rewarded adapter that was shown.
- (void)impressionWithRewarded:(CLXAdapterRewarded *)rewarded;

/// Called when the adapter has closed the rewarded.
/// @param rewarded The rewarded adapter that was closed.
- (void)didCloseWithRewarded:(CLXAdapterRewarded *)rewarded;

/// Called when the adapter failed to show the rewarded.
/// @param rewarded The rewarded adapter that failed to show.
/// @param error The error that caused the failure.
- (void)didFailToShowWithRewarded:(CLXAdapterRewarded *)rewarded error:(NSError *)error;

/// Called when the adapter has tracked click.
/// @param rewarded The rewarded adapter that was clicked.
- (void)clickWithRewarded:(CLXAdapterRewarded *)rewarded;

/// Called when the adapter expired the rewarded.
/// @param rewarded The rewarded adapter that expired.
- (void)expiredWithRewarded:(CLXAdapterRewarded *)rewarded;

/// Deprecated — use the amount/label form below.
/// @param rewarded The rewarded adapter that triggered the reward.
- (void)userRewardWithRewarded:(CLXAdapterRewarded *)rewarded;

@optional

/// Called when the adapter rewarded the user with reward details.
/// @param rewarded The rewarded adapter that triggered the reward.
/// @param amount The reward amount from the ad network (0 if not provided).
/// @param label The reward label/currency from the ad network (nil if not provided).
- (void)userRewardWithRewarded:(CLXAdapterRewarded *)rewarded amount:(NSInteger)amount label:(nullable NSString *)label;

@end

NS_ASSUME_NONNULL_END
