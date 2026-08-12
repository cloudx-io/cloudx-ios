//
//  CLXMolocoInterstitial.h
//  CloudXMolocoAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Moloco interstitial adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Moloco interstitial ads including loading, showing, and cleanup.
 */
@interface CLXMolocoInterstitial : CLXAdapterInterstitial <MolocoInterstitialDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;

@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
