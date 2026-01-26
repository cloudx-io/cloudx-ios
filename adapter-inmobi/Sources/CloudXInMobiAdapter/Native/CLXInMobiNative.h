//
//  CLXInMobiNative.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiNative : NSObject <IMNativeDelegate, CLXAdapterNative>

@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable) IMNative *native;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, assign, readonly) long long placementID;
@property (nonatomic, strong, nullable) NSData *bidPayload;

/// The container view for the native ad
@property (nonatomic, strong, readonly, nullable) UIView *nativeView;

/// Native ad content properties (populated after load)
@property (nonatomic, copy, readonly, nullable) NSString *adTitle;
@property (nonatomic, copy, readonly, nullable) NSString *adDescription;
@property (nonatomic, copy, readonly, nullable) NSString *adCtaText;
@property (nonatomic, strong, readonly, nullable) UIImage *adIcon;

/// Get the media view for video/image content (InMobi SDK 11.x)
- (nullable UIView *)getMediaView;

/// Register views for interaction tracking using InMobi SDK 11.x API
/// @param containerView The parent view containing all native ad elements
/// @param titleView The view displaying the ad title
/// @param descriptionView The view displaying the ad description
/// @param ctaView The call-to-action button
/// @param iconView The view displaying the ad icon
- (void)registerViewForInteractionWithContainer:(UIView *)containerView
                                      titleView:(nullable UILabel *)titleView
                                descriptionView:(nullable UILabel *)descriptionView
                                        ctaView:(nullable UIView *)ctaView
                                       iconView:(nullable UIImageView *)iconView;

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterNativeDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

/// Check if the native ad is ready to be shown
- (BOOL)isReady;

@end

NS_ASSUME_NONNULL_END

