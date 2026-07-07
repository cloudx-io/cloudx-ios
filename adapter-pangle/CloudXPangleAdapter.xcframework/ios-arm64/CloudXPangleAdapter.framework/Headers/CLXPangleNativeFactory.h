//
//  CLXPangleNativeFactory.h
//  CloudXPangleAdapter
//

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/// Factory that creates Pangle native ad adapters.
/// Discovered at runtime by CLXAdapterFactoryResolver via the
/// `CLX{Network}NativeFactory` naming convention (network = "pangle").
@interface CLXPangleNativeFactory : CLXAdapterNativeFactory
@end

NS_ASSUME_NONNULL_END
