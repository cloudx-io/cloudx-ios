//
//  CLXMetaBanner.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaBanner : NSObject <FBAdViewDelegate, CLXAdapterBanner, CLXDestroyable>

@property (nonatomic, strong, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, assign) BOOL timeout;

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              type:(CLXBannerType)type
                          delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 