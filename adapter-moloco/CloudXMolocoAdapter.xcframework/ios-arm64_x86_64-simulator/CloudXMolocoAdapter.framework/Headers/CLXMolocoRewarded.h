//
//  CLXMolocoRewarded.h
//  CloudXMolocoAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Moloco rewarded adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Moloco rewarded ads including loading, showing, and reward handling.
 */
@interface CLXMolocoRewarded : CLXAdapterRewarded <MolocoRewardedDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;

@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
