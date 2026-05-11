/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterInterstitial.h
 * @brief Abstract base class for interstitial adapters
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXDestroyable.h>
#import <CloudXCore/CLXExport.h>

@protocol CLXAdapterInterstitialDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for interstitial adapters.
 *
 * Subclass per ad network. Required overrides: @c -load,
 * @c -showFromViewController:, @c -destroy. Subclasses populate the
 * @protected ivars at construction time and during the load lifecycle.
 * The @c delegate retain-cycle break must happen in @c -destroy.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterInterstitial : NSObject <CLXDestroyable> {
@protected
    id<CLXAdapterInterstitialDelegate> _Nullable _delegate;
    NSString *_sdkVersion;
    NSString *_network;
    NSString *_bidID;
    BOOL _isReady;
}

/// Delegate for the adapter, used to notify about ad events.
/// Strong to keep the callback chain alive through the ad lifecycle.
/// Cycle is broken in @c -destroy.
@property (nonatomic, strong, nullable) id<CLXAdapterInterstitialDelegate> delegate;

/// SDK version of the adapter.
@property (nonatomic, copy, readonly) NSString *sdkVersion;

/// Network name of the adapter. e.g. "AdMob", "Facebook".
@property (nonatomic, copy, readonly) NSString *network;

/// Ad id from bid response.
@property (nonatomic, copy, readonly) NSString *bidID;

/// Whether the ad is ready to be shown.
@property (nonatomic, assign, readonly) BOOL isReady;

/// Loads the adapter interstitial. Subclass MUST override.
- (void)load;

/// Shows the adapter interstitial. Subclass MUST override.
- (void)showFromViewController:(UIViewController *)viewController;

/// Destroys the adapter and breaks the retain cycle by nilling the delegate.
/// Subclass MUST override.
- (void)destroy;

@end

/// Delegate for the interstitial adapter.
@protocol CLXAdapterInterstitialDelegate <NSObject>

- (void)didLoadWithInterstitial:(CLXAdapterInterstitial *)interstitial;
- (void)didFailToLoadWithInterstitial:(CLXAdapterInterstitial *)interstitial error:(NSError *)error;
- (void)didShowWithInterstitial:(CLXAdapterInterstitial *)interstitial;
- (void)didFailToShowWithInterstitial:(CLXAdapterInterstitial *)interstitial error:(NSError *)error;
- (void)impressionWithInterstitial:(CLXAdapterInterstitial *)interstitial;
- (void)didCloseWithInterstitial:(CLXAdapterInterstitial *)interstitial;
- (void)clickWithInterstitial:(CLXAdapterInterstitial *)interstitial;
- (void)expiredWithInterstitial:(CLXAdapterInterstitial *)interstitial;

@end

NS_ASSUME_NONNULL_END
