//
//  CLXMetaRewarded.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaRewarded : NSObject <FBRewardedVideoAdDelegate, CLXAdapterRewarded>

@property (nonatomic, weak, nullable) id<CLXAdapterRewardedDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong) FBRewardedVideoAd *rewarded;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, assign) NSTimeInterval timeoutInterval; // For internal use if needed
@property (nonatomic, assign) BOOL isLoading;

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(NSString *)placementID
                            bidID:(NSString *)bidID
                         delegate:(id<CLXAdapterRewardedDelegate>)delegate;

// Server-side reward validation support (per Meta official docs)
- (void)setRewardDataWithUserID:(NSString *)userID withCurrency:(NSString *)currency;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 