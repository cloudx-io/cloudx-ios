//
//  CLXInMobiInterstitial.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiInterstitial : NSObject <IMInterstitialDelegate, CLXAdapterInterstitial>

@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
