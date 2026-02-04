//
//  CLXInMobiBanner.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiBanner : NSObject <IMBannerDelegate, CLXAdapterBanner>

@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable) IMBanner *banner;
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, assign, readonly) long long placementID;

/**
 * CloudX ad unit name for error messages and logging.
 *
 * This is separate from `placementID` because:
 * - `placementID` is InMobi's internal numeric identifier used by their SDK
 * - `adUnitName` is CloudX's human-readable identifier shown in error messages,
 *   logs, and delegate callbacks to help publishers identify which ad unit failed
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;
@property (nonatomic, strong, nullable) NSData *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              size:(CGSize)size
                    viewController:(UIViewController *)viewController
                          delegate:(id<CLXAdapterBannerDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END

