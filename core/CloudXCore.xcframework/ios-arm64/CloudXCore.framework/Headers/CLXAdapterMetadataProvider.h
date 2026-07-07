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
 * Adapters released with metadata API v1 MUST override @c -adapterVersion,
 * @c -networkSdkVersion, @c -minimumSdkVersion, @c -minimumSdkVersionCode,
 * and @c -adapterApiVersion. The default implementations exist only to keep
 * future additive metadata fields binary-compatible with already released
 * adapters. Required v1 defaults assert in debug builds and fail closed.
 */
#define CLXAdapterAPIVersion 1

CLX_PUBLIC_ADAPTER
@interface CLXAdapterMetadataProvider : NSObject

@property (nonatomic, copy, readonly) NSString *adapterVersion;
@property (nonatomic, copy, readonly) NSString *networkSdkVersion;
@property (nonatomic, copy, readonly) NSString *minimumSdkVersion;
@property (nonatomic, assign, readonly) NSInteger minimumSdkVersionCode;
@property (nonatomic, assign, readonly) NSInteger adapterApiVersion;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *extras;

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
