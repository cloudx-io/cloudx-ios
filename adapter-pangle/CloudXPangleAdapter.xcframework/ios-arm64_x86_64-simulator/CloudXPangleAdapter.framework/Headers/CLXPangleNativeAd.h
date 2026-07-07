//
//  CLXPangleNativeAd.h
//  CloudXPangleAdapter
//

#import <CloudXCore/CLXNativeAd.h>

NS_ASSUME_NONNULL_BEGIN

@class PAGLNativeAd;
@protocol CLXAdapterNativeDelegate;

/// CloudX native ad object backed by a Pangle `PAGLNativeAd`. Maps Pangle's
/// material into the CloudX builder and registers the rendered views with Pangle
/// for click / impression tracking.
@interface CLXPangleNativeAd : CLXNativeAd

@property (nonatomic, weak, nullable) id<CLXAdapterNativeDelegate> adapterDelegate;

- (instancetype)initWithNativeAd:(PAGLNativeAd *)nativeAd;
- (void)stopTracking;

@end

NS_ASSUME_NONNULL_END
