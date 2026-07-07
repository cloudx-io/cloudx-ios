//
//  CLXPangleInterstitial.h
//  CloudXPangleAdapter
//

#import <Foundation/Foundation.h>
#import <PAGAdSDK/PAGAdSDK.h>

#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Pangle interstitial adapter.
 *
 * Manages the lifecycle of Pangle interstitial ads including loading,
 * showing, and cleanup.
 */
@interface CLXPangleInterstitial : CLXAdapterInterstitial <PAGLInterstitialAdDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;
@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
