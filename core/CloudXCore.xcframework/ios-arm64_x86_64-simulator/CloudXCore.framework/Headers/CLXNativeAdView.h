/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXNativeAd;
@class CLXNativeAdViewBinder;

CLX_PUBLIC
@interface CLXNativeAdView : UIView

#pragma mark - Sub-View Slots (IBOutlet-compatible)

@property (nonatomic, weak, nullable) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak, nullable) IBOutlet UILabel *advertiserLabel;
@property (nonatomic, weak, nullable) IBOutlet UILabel *bodyLabel;
@property (nonatomic, weak, nullable) IBOutlet UIButton *callToActionButton;
@property (nonatomic, weak, nullable) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak, nullable) IBOutlet UIView *iconContentView
    __attribute__((deprecated("Use iconImageView instead.")));
@property (nonatomic, weak, nullable) IBOutlet UIView *optionsContentView;
@property (nonatomic, weak, nullable) IBOutlet UIView *mediaContentView;
@property (nonatomic, weak, nullable) IBOutlet UIView *starRatingContentView;

#pragma mark - Methods

- (void)bindViewsWithViewBinder:(CLXNativeAdViewBinder *)binder;

- (UIView *)getMainView;

- (void)renderWithNativeAd:(CLXNativeAd *)nativeAd;

+ (CLXNativeAdView *)viewFromAd:(CLXNativeAd *)ad;
+ (CLXNativeAdView *)viewFromAd:(CLXNativeAd *)ad withTemplate:(NSString *)templateName;

- (void)prepareForReuse;

@end

NS_ASSUME_NONNULL_END
