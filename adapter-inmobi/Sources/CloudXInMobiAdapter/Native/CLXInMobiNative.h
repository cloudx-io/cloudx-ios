//
//  CLXInMobiNative.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <InMobiSDK/InMobiSDK.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiNative : NSObject <IMNativeDelegate, CLXAdapterNative>

@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> delegate;
@property (nonatomic, assign) BOOL timeout;
@property (nonatomic, strong, nullable) IMNative *native;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, strong, readonly) NSString *bidID;
@property (nonatomic, assign, readonly) long long placementID;
@property (nonatomic, strong, nullable) NSData *bidPayload;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/// The rendered native ad view (from InMobi's primaryViewOfWidth:)
@property (nonatomic, strong, readonly, nullable) UIView *nativeView;

/// Native ad content properties (populated after load)
@property (nonatomic, copy, readonly, nullable) NSString *adTitle;
@property (nonatomic, copy, readonly, nullable) NSString *adDescription;
@property (nonatomic, copy, readonly, nullable) NSString *adCtaText;
@property (nonatomic, strong, readonly, nullable) UIImage *adIcon;

- (instancetype)initWithBidPayload:(nullable NSData *)bidPayload
                       placementID:(long long)placementID
                             bidID:(NSString *)bidID
                          delegate:(id<CLXAdapterNativeDelegate>)delegate;

- (void)load;
- (void)showFromViewController:(UIViewController *)viewController;
- (void)destroy;

/// Check if the native ad is ready to be shown
- (BOOL)isReady;

/// Get the primary view for display at a specific width
- (nullable UIView *)primaryViewOfWidth:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END

