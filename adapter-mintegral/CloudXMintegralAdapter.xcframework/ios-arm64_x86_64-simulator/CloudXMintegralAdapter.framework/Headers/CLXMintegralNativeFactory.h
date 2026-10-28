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
 * Custom-rendered: loads discrete native assets via Mintegral's custom rendering
 * bidding API so CloudX renders them using standard templates.
 */
@interface CLXMintegralNativeFactory : CLXAdapterNativeFactory

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
