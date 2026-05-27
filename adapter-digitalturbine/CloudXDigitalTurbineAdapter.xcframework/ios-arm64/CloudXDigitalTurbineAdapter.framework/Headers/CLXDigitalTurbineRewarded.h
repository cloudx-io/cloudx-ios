//
//  CLXDigitalTurbineRewarded.h
//  CloudXDigitalTurbineAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXDigitalTurbineRewarded : CLXAdapterRewarded

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                            spotID:(nullable NSString *)spotID
                        adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                           isMuted:(nullable NSNumber *)isMuted;

@end

NS_ASSUME_NONNULL_END
