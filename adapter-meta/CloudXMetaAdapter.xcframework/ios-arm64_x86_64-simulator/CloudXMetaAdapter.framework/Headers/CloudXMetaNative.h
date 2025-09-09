//
//  CloudXMetaNative.h
//  CloudXMetaAdapter
//
//  Created by CloudX on 2024-02-14.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

NS_ASSUME_NONNULL_BEGIN

@interface CloudXMetaNative : NSObject <FBNativeAdDelegate, CloudXAdapterNative>

@property (nonatomic, weak, nullable) id<CloudXAdapterNativeDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong) FBNativeAd *nativeAd;
@property (nonatomic, readonly) UIView *nativeView;
@property (nonatomic, strong) NSString *sdkVersion;
@property (nonatomic, copy) NSString *bidID;
@property (nonatomic, copy) NSString *placementID;
@property (nonatomic, copy) NSString *bidPayload;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

- (instancetype)initWithBidPayload:(NSString *)bidPayload
                      placementID:(NSString *)placementID
                           bidID:(NSString *)bidID
                            type:(CloudXNativeTemplate)type
                   viewController:(UIViewController *)viewController
                        delegate:(id<CloudXAdapterNativeDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

@end

NS_ASSUME_NONNULL_END 
