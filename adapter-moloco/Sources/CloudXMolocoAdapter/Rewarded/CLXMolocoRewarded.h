//
//  CLXMolocoRewarded.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MolocoSDK/MolocoSDK.h>
#import <CloudXCore/CLXAdapterRewarded.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMolocoRewarded : NSObject <MolocoRewardedDelegate, CLXAdapterRewarded>

@property (nonatomic, weak, nullable) id<CLXAdapterRewardedDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, strong, readonly) NSString *placementID;
@property (nonatomic, copy, readonly, nullable) NSString *placementName;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, strong, nullable) MolocoRewardedAd *rewardedAd;

/**
 * Initialize Moloco rewarded adapter
 * 
 * @param bidPayload Optional bid payload from server
 * @param placementID Moloco placement ID (now nullable - validation deferred to load())
 * @param placementName CloudX placement name for error messages (nullable)
 * @param bidID Bid identifier
 * @param delegate Adapter delegate for callbacks
 * @return Initialized adapter instance
 *
 * @discussion As of v1.3.0, placementID can be nil. Validation occurs in load()
 *             and errors are reported via delegate callback.
 * @since 1.3.0 placementID parameter is now nullable
 * @since 1.4.0 placementName parameter added for better error messages
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END

