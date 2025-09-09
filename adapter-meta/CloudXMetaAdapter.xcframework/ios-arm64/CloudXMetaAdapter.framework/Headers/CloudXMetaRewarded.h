//
//  CloudXMetaRewarded.h
//  CloudXMetaAdapter
//
//  Created by CloudX on 2024-02-14.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface CloudXMetaRewarded : NSObject <FBRewardedVideoAdDelegate, CloudXAdapterRewarded>

@property (nonatomic, weak, nullable) id<CloudXAdapterRewardedDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong) FBRewardedVideoAd *rewarded;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, assign) NSTimeInterval timeoutInterval; // For internal use if needed

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                      placementID:(NSString *)placementID
                           bidID:(NSString *)bidID
                        delegate:(id<CloudXAdapterRewardedDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 