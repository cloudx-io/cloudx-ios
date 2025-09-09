//
//  CloudXMetaBanner.h
//  CloudXMetaAdapter
//
//  Created by CloudX on 2024-02-14.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CloudXMetaBanner : NSObject <FBAdViewDelegate, CloudXAdapterBanner, Destroyable>

@property (nonatomic, weak, nullable) id<CloudXAdapterBannerDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable) FBAdView *bannerView;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                      placementID:(NSString *)placementID
                           bidID:(NSString *)bidID
                            type:(CloudXBannerType)type
                   viewController:(UIViewController *)viewController
                        delegate:(id<CloudXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 