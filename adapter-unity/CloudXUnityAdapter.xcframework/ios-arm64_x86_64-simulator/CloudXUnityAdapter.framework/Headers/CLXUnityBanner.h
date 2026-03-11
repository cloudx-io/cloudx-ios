//
//  CLXUnityBanner.h
//  CloudXUnityAdapter
//

#import <Foundation/Foundation.h>
#import <UnityAds/UnityAds.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXUnityBanner : NSObject <CLXAdapterBanner, UADSBannerAdDelegate>

@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, copy, readonly) NSString *network;
@property (nonatomic, copy, readonly) NSString *bidID;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable, readonly) UIView *bannerView;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type
                          delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
