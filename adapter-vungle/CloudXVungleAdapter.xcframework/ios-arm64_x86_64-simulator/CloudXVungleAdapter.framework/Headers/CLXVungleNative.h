//
//  CLXVungleNative.h
//  CloudXVungleAdapter
//
//  Created by CloudX Team on 2024-09-14.
//

#import <Foundation/Foundation.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

// Conditional import for CloudXCore header
#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Vungle native adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Vungle native ads including loading, view registration, and cleanup.
 */
@interface CLXVungleNative : NSObject <VungleNativeDelegate, CLXAdapterNative>

/**
 * CloudX adapter delegate for receiving ad events
 */
@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> delegate;

/**
 * Flag indicating if the ad loading timed out
 */
@property (nonatomic, assign) BOOL timeout;

/**
 * View containing the native ad (custom layout created by app)
 */
@property (nonatomic, strong, readonly, nullable) UIView *nativeView;

/**
 * SDK version of the Vungle SDK
 */
@property (nonatomic, strong, readonly) NSString *sdkVersion;

/**
 * Vungle placement ID for this ad
 */
@property (nonatomic, copy, readonly) NSString *placementID;

/**
 * CloudX bid ID
 */
@property (nonatomic, copy, readonly) NSString *bidID;

/**
 * The underlying Vungle native ad instance
 */
@property (nonatomic, strong, nullable) VungleNative *vungleNative;

/**
 * Bid payload for programmatic ads (nil for waterfall)
 */
@property (nonatomic, copy, nullable) NSString *bidPayload;

/**
 * Timeout interval for ad loading
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 * Initializes a new Vungle native adapter
 * @param bidPayload The bid payload for programmatic ads (nil for waterfall)
 * @param placementID The Vungle placement ID
 * @param bidID The CloudX bid ID
 * @param delegate The CloudX adapter delegate
 * @return Initialized native adapter
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterNativeDelegate>)delegate;

/**
 * Loads the native ad
 */
- (void)load;

/**
 * Shows the native ad from the given view controller
 * @param viewController The view controller to show from
 */
- (void)showFromViewController:(UIViewController *)viewController;

/**
 * Registers views for interaction with the native ad
 * @param containerView The container view that holds the native ad
 * @param mediaView The media view for video/image content
 * @param iconImageView Optional icon image view
 * @param viewController The view controller hosting the ad
 * @param clickableViews Array of views that should be clickable
 */
- (void)registerViewForInteraction:(UIView *)containerView
                         mediaView:(UIView *)mediaView
                     iconImageView:(nullable UIImageView *)iconImageView
                    viewController:(nullable UIViewController *)viewController
                    clickableViews:(nullable NSArray<UIView *> *)clickableViews;

/**
 * Unregisters the native ad view
 */
- (void)unregisterView;

/**
 * Destroys the native ad and cleans up resources
 */
- (void)destroy;

/**
 * Gets the native ad title
 */
@property (nonatomic, readonly, nullable) NSString *title;

/**
 * Gets the native ad body text
 */
@property (nonatomic, readonly, nullable) NSString *bodyText;

/**
 * Gets the native ad call-to-action text
 */
@property (nonatomic, readonly, nullable) NSString *callToAction;

/**
 * Gets the native ad advertiser name
 */
@property (nonatomic, readonly, nullable) NSString *advertiser;

/**
 * Gets the native ad star rating
 */
@property (nonatomic, readonly) double starRating;

/**
 * Gets the native ad sponsored text
 */
@property (nonatomic, readonly, nullable) NSString *sponsoredText;

@end

NS_ASSUME_NONNULL_END
