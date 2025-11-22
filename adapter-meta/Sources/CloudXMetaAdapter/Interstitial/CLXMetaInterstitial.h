//
//  CLXMetaInterstitial.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaInterstitial : NSObject <FBInterstitialAdDelegate, CLXAdapterInterstitial>

@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong) FBInterstitialAd *interstitial;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 * Initialize Meta interstitial adapter
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
                         delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 
