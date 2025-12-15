#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>
#import <CloudXCore/CLXAdapterBanner.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CLXMintegralBanner - Mintegral Banner Ad Implementation
 *
 * Uses MTGBannerAdView which supports both bidding and waterfall.
 * Includes proper banner configuration: autoRefreshTime, showCloseButton.
 */
@interface CLXMintegralBanner : NSObject <MTGBannerAdViewDelegate, CLXAdapterBanner>

@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, strong, readonly) NSString *placementID;
@property (nonatomic, strong, readonly) NSString *unitID;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, copy, nullable) NSString *creativeID;
@property (nonatomic, assign) NSInteger autoRefreshTime;  // 0 = disabled (default)
@property (nonatomic, assign) BOOL showCloseButton;       // NO = hidden (default)
@property (nonatomic, strong, nullable) MTGBannerAdView *bannerView;

- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(NSString *)placementID
                            unitID:(NSString *)unitID
                              size:(CGSize)size
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterBannerDelegate>)delegate;

- (void)load;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END

