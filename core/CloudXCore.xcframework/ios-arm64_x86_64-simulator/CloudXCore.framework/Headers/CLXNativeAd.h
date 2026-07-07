/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAdImage;
@class CLXNativeAdBuilder;
@class CLXNativeAdView;

typedef void (^CLXNativeAdBuilderBlock)(CLXNativeAdBuilder *builder);

CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagTitleLabel;
CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagMediaViewContainer;
CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagIconImageView;
CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagBodyLabel;
CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagCallToActionButton;
CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagAdvertiserLabel;
CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagOptionsContentView;
CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagStarRatingContentView;
CLX_PUBLIC
extern NSInteger const CLXNativeAdViewTagIconContentView
    __attribute__((deprecated("Use CLXNativeAdViewTagIconImageView instead.")));

CLX_PUBLIC
@interface CLXNativeAd : NSObject

#pragma mark - Asset Properties (readonly, set via builder)

@property (nonatomic, copy, readonly, nullable) NSString *title;
@property (nonatomic, copy, readonly, nullable) NSString *advertiser;
@property (nonatomic, copy, readonly, nullable) NSString *body;
@property (nonatomic, copy, readonly, nullable) NSString *callToAction;
@property (nonatomic, strong, readonly, nullable) CLXNativeAdImage *icon;
@property (nonatomic, strong, readonly, nullable) CLXNativeAdImage *mainImage;
@property (nonatomic, strong, readonly, nullable) UIView *iconView;
@property (nonatomic, strong, readonly, nullable) UIView *mediaView;
@property (nonatomic, strong, readonly, nullable) UIView *optionsView;
@property (nonatomic, assign, readonly) CGFloat mediaContentAspectRatio;
@property (nonatomic, strong, readonly, nullable) NSNumber *starRating;

#pragma mark - Video Properties

/**
 * Whether the ad contains video content.
 *
 * Adapter-dependent. Only meaningful when the underlying ad network reports
 * creative format information. When the adapter does not distinguish video
 * from static content, this returns NO.
 *
 * Currently supported by: Meta Audience Network (FAN).
 */
@property (nonatomic, assign, readonly) BOOL isVideoContent;

/**
 * Duration of the video creative in seconds, or 0 if unknown/not applicable.
 *
 * @note This value may not be available immediately at load time. Some ad networks
 *       only report duration after the media view has finished loading its content,
 *       which occurs after didLoadNativeAd:forAd: fires. If you need the duration
 *       for UI display, check this property after the media view is rendered (e.g.,
 *       after calling renderNativeAdView:withAd:) or poll it after a short delay.
 *       A value of 0 does not necessarily mean the ad is not video — check
 *       isVideoContent instead.
 */
@property (nonatomic, assign, readonly) NSTimeInterval videoDuration;

#pragma mark - Lifecycle Properties

@property (nonatomic, assign, readonly, getter=isExpired) BOOL expired;

#pragma mark - Initialization

- (instancetype)initWithBuilderBlock:(NS_NOESCAPE CLXNativeAdBuilderBlock)builderBlock NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Adapter Override Points

- (BOOL)prepareForInteractionClickableViews:(NSArray<UIView *> *)clickableViews
                              withContainer:(UIView *)container;

- (BOOL)isContainerClickable;

/**
 * Whether the adapter returns a fully-composed `mediaView` that should be used
 * as the entire ad surface, bypassing template assembly.
 *
 * Distinct from `isContainerClickable`, which describes the *click* model
 * (single container tap vs. per-view registration). An adapter may be
 * container-clickable while still relying on CloudX template rendering of its
 * raw assets (e.g. Moloco). Only override to YES when the underlying SDK
 * returns a pre-rendered view (e.g. Mintegral's `fetchAdView`, CloudX renderer).
 *
 * Default: NO.
 */
- (BOOL)isSelfRendered;

/**
 * Whether the adapter's media view must stay visible on-screen for its
 * impression to fire.
 *
 * Some partner SDKs key impression viewability on the registered media view
 * actually being on-screen. In the space-constrained 320x50 compact banner
 * template, CloudX otherwise collapses the media host to reclaim room for the
 * title and CTA — which would stop such adapters from ever registering an
 * impression (and paying revenue) in that slot. Override to YES to force a
 * visible media thumbnail in the compact banner layout.
 *
 * Only affects the compact banner (320x50) template; larger templates render a
 * full media area for every adapter regardless of this value.
 *
 * Default: NO.
 */
- (BOOL)requiresVisibleMediaViewForImpression;

- (void)performClick;

@end

NS_ASSUME_NONNULL_END
