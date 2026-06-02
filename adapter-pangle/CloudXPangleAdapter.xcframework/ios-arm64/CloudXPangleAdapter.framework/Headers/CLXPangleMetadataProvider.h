//
//  CLXPangleMetadataProvider.h
//  CloudXPangleAdapter
//

#import <Foundation/Foundation.h>

#if __has_include(<CloudXCore/CLXAdapterMetadataProvider.h>)
#import <CloudXCore/CLXAdapterMetadataProvider.h>
#else
#import <CloudXCore/CloudXCore.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CLXPangleMetadataProvider : CLXAdapterMetadataProvider
@end

NS_ASSUME_NONNULL_END
