//
//  CLXInMobiNativeFactory.h
//  CloudXInMobiAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory producing InMobi native adapters (`CLXInMobiNative`).
 *
 * Auto-discovered by `CLXAdapterFactoryResolver` and registered in
 * `CLXAdNetworkFactories.native`. Invoked by `CLXNativeBannerBridge` when an
 * InMobi bid with native `mtype` is routed through the banner pipeline.
 */
@interface CLXInMobiNativeFactory : CLXAdapterNativeFactory

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
