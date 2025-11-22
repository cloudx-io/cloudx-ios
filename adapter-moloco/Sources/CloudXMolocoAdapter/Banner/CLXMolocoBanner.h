//
//  CLXMolocoBanner.h
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MolocoSDK/MolocoSDK.h>
#import <CloudXCore/CLXAdapterBanner.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMolocoBanner : NSObject <MolocoBannerDelegate, CLXAdapterBanner>

@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *network;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, strong, readonly) NSString *placementID;
@property (nonatomic, copy, nullable) NSString *bidPayload;
@property (nonatomic, strong, nullable) MolocoBannerView *bannerView;

/**
 * Initialize Moloco banner adapter
 * 
 * @param bidPayload Optional bid payload from server
 * @param placementID Moloco placement ID (now nullable - validation deferred to load())
 * @param bidID Bid identifier
 * @param delegate Adapter delegate for callbacks
 * @param adSize Banner ad size
 * @return Initialized adapter instance
 *
 * @discussion As of v1.3.0, placementID can be nil. Validation occurs in load()
 *             and errors are reported via delegate callback.
 * @since 1.3.0 placementID parameter is now nullable
 */
- (instancetype)initWithBidPayload:(nullable NSString *)bidPayload
                       placementID:(nullable NSString *)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterBannerDelegate>)delegate
                            adSize:(CLXBannerAdSize)adSize;

- (void)load;
- (UIView *)view;

@end

NS_ASSUME_NONNULL_END

