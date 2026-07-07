/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstraction over the subset of IASDKCore's `IANativeAdAssets` the adapter
 * consumes.
 *
 * `IANativeAdAssets` is a Swift-backed class whose asset accessors are
 * read-only and cannot be instantiated with controlled values in a unit test.
 * Depending on this protocol (which `IANativeAdAssets` satisfies via the
 * category declared below) lets the adapter be exercised with a deterministic
 * test double and keeps the dependency inverted on the abstraction rather than
 * the concrete SDK type.
 *
 * IASDKCore 8.4.7 exposes the following surface on `IANativeAdAssets`:
 *   adTitle, adDescription, callToActionText, appIcon, mediaView,
 *   mediaAspectRatio, registerViewForInteraction:mediaView:iconView:clickableViews:
 *
 * Note: advertiserName, creativeId, and isReady are NOT present in 8.4.x.
 * Re-validate this protocol on every Fyber_Marketplace_SDK upgrade.
 */
@protocol CLXDigitalTurbineNativeAdapting <NSObject>

@property (nonatomic, readonly, copy, nullable) NSString *adTitle;
@property (nonatomic, readonly, copy, nullable) NSString *adDescription;
@property (nonatomic, readonly, copy, nullable) NSString *callToActionText;
@property (nonatomic, readonly, strong, nullable) UIView *appIcon;
@property (nonatomic, readonly, strong) UIView *mediaView;
@property (nonatomic, readonly, strong, nullable) NSNumber *mediaAspectRatio;

- (void)registerViewForInteraction:(nullable UIView *)rootView
                         mediaView:(nullable UIView *)mediaView
                          iconView:(nullable UIView *)iconView
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews;

@end

NS_ASSUME_NONNULL_END
