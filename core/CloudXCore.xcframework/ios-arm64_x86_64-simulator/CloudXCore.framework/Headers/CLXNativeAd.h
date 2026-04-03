/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAdImage;
@class CLXNativeAdBuilder;
@class CLXNativeAdView;

typedef void (^CLXNativeAdBuilderBlock)(CLXNativeAdBuilder *builder);

extern NSInteger const CLXNativeAdViewTagTitleLabel;
extern NSInteger const CLXNativeAdViewTagMediaViewContainer;
extern NSInteger const CLXNativeAdViewTagIconImageView;
extern NSInteger const CLXNativeAdViewTagBodyLabel;
extern NSInteger const CLXNativeAdViewTagCallToActionButton;
extern NSInteger const CLXNativeAdViewTagAdvertiserLabel;
extern NSInteger const CLXNativeAdViewTagOptionsContentView;
extern NSInteger const CLXNativeAdViewTagStarRatingContentView;
extern NSInteger const CLXNativeAdViewTagIconContentView
    __attribute__((deprecated("Use CLXNativeAdViewTagIconImageView instead.")));

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

- (BOOL)shouldPrepareViewForInteractionOnMainThread;

- (BOOL)isContainerClickable;

- (void)performClick;

@end

NS_ASSUME_NONNULL_END
