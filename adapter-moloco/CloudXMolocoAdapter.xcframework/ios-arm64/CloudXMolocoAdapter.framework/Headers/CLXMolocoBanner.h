//
//  CLXMolocoBanner.h
//  CloudXMolocoAdapter
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MolocoSDK/MolocoSDK-Swift.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Moloco banner adapter implementing CloudX adapter protocol.
 * Manages the lifecycle of Moloco banner/MREC ads including loading, showing, and cleanup.
 * Supports standard banner (320x50) and MREC (300x250).
 */
@interface CLXMolocoBanner : CLXAdapterBanner <MolocoBannerDelegate>

@property (nonatomic, copy, readonly) NSString *placementID;

/**
 * CloudX ad unit name for error messages and logging.
 */
@property (nonatomic, copy, readonly, nullable) NSString *adUnitName;

@property (nonatomic, assign, readonly) CLXBannerType bannerType;

@property (nonatomic, copy, nullable) NSString *bidPayload;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type;

@end

NS_ASSUME_NONNULL_END
