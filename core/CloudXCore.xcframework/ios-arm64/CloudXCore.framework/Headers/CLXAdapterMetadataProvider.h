/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for adapter metadata providers.
 *
 * Each adapter module subclasses this so the SDK can discover which adapters
 * are installed and include their versions in the config request. The server
 * uses this to detect mismatches between dashboard configuration and the
 * adapters actually bundled in the app.
 *
 * Subclass MUST override @c -adapterVersion and @c -networkSdkVersion getters
 * to return per-adapter constants.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterMetadataProvider : NSObject

@property (nonatomic, copy, readonly) NSString *adapterVersion;
@property (nonatomic, copy, readonly) NSString *networkSdkVersion;

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
