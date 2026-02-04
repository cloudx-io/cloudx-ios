//
//  CLXMolocoInterstitial.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MolocoSDK/MolocoSDK.h>
#import <CloudXCore/CLXAdapterInterstitial.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMolocoInterstitial : NSObject <MolocoInterstitialDelegate, CLXAdapterInterstitial>

@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, strong, readonly) NSString *placementID;

/**
 * CloudX ad unit name for error messages and logging.
 *
 * This is separate from `placementID` because:
 * - `placementID` is Moloco's internal identifier used by their SDK
 * - `adUnitName` is CloudX's human-readable identifier shown in error messages,
 *   logs, and delegate callbacks to help publishers identify which ad unit failed
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, strong, nullable) MolocoInterstitial *interstitial;

/**
 * Initialize Moloco interstitial adapter
 * 
 * @param bidPayload Optional bid payload from server
 * @param placementID Moloco placement ID (now nullable - validation deferred to load())
 * @param adUnitName CloudX placement name for error messages (nullable)
 * @param bidID Bid identifier
 * @param delegate Adapter delegate for callbacks
 * @return Initialized adapter instance
 *
 * @discussion As of v1.3.0, placementID can be nil. Validation occurs in load()
 *             and errors are reported via delegate callback.
 * @since 1.3.0 placementID parameter is now nullable
 * @since 1.4.0 adUnitName parameter added for better error messages
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END

