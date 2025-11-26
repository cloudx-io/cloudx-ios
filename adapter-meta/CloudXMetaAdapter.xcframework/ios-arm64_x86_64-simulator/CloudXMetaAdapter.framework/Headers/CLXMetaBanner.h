//
//  CLXMetaBanner.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import <Foundation/Foundation.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaBanner : NSObject <FBAdViewDelegate, CLXAdapterBanner, CLXDestroyable>

@property (nonatomic, weak, nullable) id<CLXAdapterBannerDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable) FBAdView *bannerView;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, assign, readonly) BOOL isFlexibleSize;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 * Initialize Meta banner adapter
 * 
 * @param bidPayload Bid payload from server
 * @param placementID Meta placement ID (now nullable - validation deferred to load())
 * @param bidID Bid identifier
 * @param type Banner type
 * @param viewController View controller for presentation
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
                             type:(CLXBannerType)type
                    viewController:(UIViewController *)viewController
                         delegate:(id<CLXAdapterBannerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END 