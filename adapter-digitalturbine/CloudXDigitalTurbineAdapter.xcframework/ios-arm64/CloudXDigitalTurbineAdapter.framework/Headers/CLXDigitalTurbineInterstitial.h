//
//  CLXDigitalTurbineInterstitial.h
//  CloudXDigitalTurbineAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXDigitalTurbineInterstitial : CLXAdapterInterstitial

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                            spotID:(nullable NSString *)spotID
                        adUnitName:(nullable NSString *)adUnitName
                           isMuted:(nullable NSNumber *)isMuted
                            logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
