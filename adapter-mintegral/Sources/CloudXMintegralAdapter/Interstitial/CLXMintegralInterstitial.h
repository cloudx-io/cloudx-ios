#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKNewInterstitial/MTGSDKNewInterstitial.h>
#import <MTGSDKNewInterstitial/MTGNewInterstitialAdManager.h>
#import <CloudXCore/CLXAdapterInterstitial.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralInterstitial - Mintegral Interstitial Ad Implementation
 *
 * Uses the NEW Interstitial API (MTGNewInterstitialBidAdManager) as recommended
 * by Mintegral and used by AppLovin's adapter.
 */
@interface CLXMintegralInterstitial : NSObject <MTGNewInterstitialBidAdDelegate, CLXAdapterInterstitial>

@property (nonatomic, weak, nullable) id<CLXAdapterInterstitialDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, strong, readonly) NSString *placementID;
@property (nonatomic, strong, readonly) NSString *unitID;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy, nullable) NSString *creativeID;
@property (nonatomic, assign) BOOL playVideoMute;
@property (nonatomic, strong, nullable) MTGNewInterstitialBidAdManager *interstitialManager;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterInterstitialDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END

