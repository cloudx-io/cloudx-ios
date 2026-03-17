/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

@class CLXAdapterMetadata;

NS_ASSUME_NONNULL_BEGIN

/**
 * Discovers installed adapter MetadataProvider classes via runtime reflection
 * and collects their version info.
 *
 * Uses the same class-loading pattern as CLXAdapterFactoryResolver but runs
 * earlier — at config request time — so the server knows which adapters
 * (and versions) are present before returning config.
 */
@interface CLXAdapterMetadataResolver : NSObject

/**
 * Returns metadata for all adapters whose MetadataProvider is on the classpath.
 * @return Array of CLXAdapterMetadata, one per discovered adapter.
 */
- (NSArray<CLXAdapterMetadata *> *)resolve;

@end

NS_ASSUME_NONNULL_END
