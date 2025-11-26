//
//  CLXMetaNative.h
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMetaNative : NSObject <FBNativeAdDelegate, CLXAdapterNative>

@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong) FBNativeAd *nativeAd;
@property (nonatomic, readonly) UIView *nativeView;
@property (nonatomic, strong) NSString *sdkVersion;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy, nullable) NSString *placementID;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 * Initialize Meta native adapter
 * 
 * @param bidPayload Bid payload from server
 * @param placementID Meta placement ID (now nullable - validation deferred to load())
 * @param bidID Bid identifier
 * @param type Native template type
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
                             type:(CLXNativeTemplate)type
                    viewController:(UIViewController *)viewController
                         delegate:(id<CLXAdapterNativeDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 
