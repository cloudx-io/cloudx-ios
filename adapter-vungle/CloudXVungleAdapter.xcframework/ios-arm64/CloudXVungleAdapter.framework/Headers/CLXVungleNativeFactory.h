//
//  CLXVungleNativeFactory.h
//  CloudXVungleAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory producing Vungle native adapters (`CLXVungleNative`).
 *
 * Discovered by `CLXAdapterFactoryResolver` via the class name
 * `CLXVungleNativeFactory` under the `CloudXVungleAdapter` namespace. Registered
 * in `CLXAdNetworkFactories.native` and invoked by `CLXNativeBannerBridge` when
 * a Vungle bid with native `mtype` is routed through the banner pipeline.
 */
@interface CLXVungleNativeFactory : CLXAdapterNativeFactory

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
