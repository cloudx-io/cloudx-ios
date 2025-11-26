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
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, assign) NSTimeInterval timeoutInterval; // For internal use if needed
@property (nonatomic, assign) BOOL isLoading;

/**
 * Initialize Meta rewarded adapter
 * 
 * @param bidPayload Bid payload from server
 * @param placementID Meta placement ID (now nullable - validation deferred to load())
 * @param bidID Bid identifier
 * @param delegate Adapter delegate for callbacks
 * @return Initialized adapter instance
 *
 * @discussion As of v1.3.0, placementID can be nil. Validation occurs in load()
 *             and errors are reported via delegate callback.
 * @since 1.3.0 placementID parameter is now nullable
 */
- (instancetype)initWithBidPayload:(NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                            bidID:(NSString *)bidID
                         delegate:(id<CLXAdapterRewardedDelegate>)delegate;

// Server-side reward validation support (per Meta official docs)
- (void)setRewardDataWithUserID:(NSString *)userID withCurrency:(NSString *)currency;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 