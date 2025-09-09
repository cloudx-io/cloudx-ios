//
//  CloudXPrebidBanner.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 compliant banner ad implementation
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPrebidBanner : NSObject <CLXAdapterBanner>

@property (nonatomic, weak) id<CLXAdapterBannerDelegate> delegate;

/**
 * Initialize with bid markup from core SDK
 * This is the primary initialization method - core SDK provides the ad markup
 * after handling the auction and bid selection process
 *
 * @param adMarkup HTML/VAST markup from winning prebid bid response
 * @param hasCloseButton Whether banner should show close button
 * @param type Banner type (standard, interscroller, etc.)
 * @param viewController Parent view controller for presentation
 * @param delegate Callback delegate for ad events
 */
- (instancetype)initWithAdm:(NSString *)adMarkup
             hasClosedButton:(BOOL)hasCloseButton
                        type:(CLXBannerType)type
               viewController:(UIViewController *)viewController
                     delegate:(nullable id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 