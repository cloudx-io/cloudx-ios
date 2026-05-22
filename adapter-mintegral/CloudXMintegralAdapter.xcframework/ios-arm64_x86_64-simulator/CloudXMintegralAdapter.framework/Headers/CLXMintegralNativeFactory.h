//
//  CLXMintegralNativeFactory.h
//  CloudXMintegralAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for the Mintegral native adapter used by the native-in-banner pipeline.
 *
 * Discovered automatically by CLXAdapterFactoryResolver as `CLXMintegralNativeFactory`.
 *
 * Unlike the publisher-rendered networks (Meta/Vungle/InMobi/Moloco),
 * Mintegral is self-rendered via `fetchAdView`. The bridge detects this via
 * `[nativeAd isSelfRendered] == YES` and uses the returned view directly.
 */
@interface CLXMintegralNativeFactory : CLXAdapterNativeFactory

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
