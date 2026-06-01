//
//  CLXPangleRewarded.h
//  CloudXPangleAdapter
//

#import <Foundation/Foundation.h>
#import <PAGAdSDK/PAGAdSDK.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Pangle rewarded adapter.
 *
 * Manages the lifecycle of Pangle rewarded ads including loading, showing,
 * and reward handling.
 */
@interface CLXPangleRewarded : CLXAdapterRewarded <PAGRewardedAdDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;
@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID;

@end

NS_ASSUME_NONNULL_END
