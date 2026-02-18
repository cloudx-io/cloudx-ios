//
//  CLXInMobiBanner.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiBanner : NSObject <IMBannerDelegate, CLXAdapterBanner>

@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *sdkVersion;

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     adUnitName:(nullable NSString *)adUnitName
                             bidID:(NSString *)bidID
                              size:(CGSize)size
                    viewController:(UIViewController *)viewController
                          delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
