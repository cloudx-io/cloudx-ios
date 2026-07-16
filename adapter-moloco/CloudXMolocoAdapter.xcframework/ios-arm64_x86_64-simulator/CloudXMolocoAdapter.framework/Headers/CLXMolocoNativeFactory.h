//
//  CLXMolocoNativeFactory.h
//  CloudXMolocoAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 * Factory for creating Moloco native adapters.
 */
@interface CLXMolocoNativeFactory : CLXAdapterNativeFactory
@end

NS_ASSUME_NONNULL_END
