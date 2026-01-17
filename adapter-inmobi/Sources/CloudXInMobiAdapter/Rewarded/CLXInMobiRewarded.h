//
//  CLXInMobiRewarded.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiRewarded : NSObject <IMInterstitialDelegate, CLXAdapterRewarded>

@property (nonatomic, weak, nullable) id<CLXAdapterRewardedDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable) IMInterstitial *interstitial;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, assign, readonly) long long placementID;
@property (nonatomic, copy, readonly, nullable) NSString *placementName;
@property (nonatomic, strong, nullable) NSData *bidPayload;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                     placementName:(nullable NSString *)placementName
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterRewardedDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END

