//
//  CLXMolocoNative.h
//  CloudXMolocoAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Moloco native adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Moloco native ads including loading, asset extraction, and cleanup.
 */
@interface CLXMolocoNative : CLXAdapterNative <MolocoNativeAdDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;

@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                    nativeInAdView:(BOOL)nativeInAdView
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
