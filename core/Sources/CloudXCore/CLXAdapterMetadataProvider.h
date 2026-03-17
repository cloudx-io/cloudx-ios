/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol for adapters to report their version metadata.
 *
 * Each adapter module provides a class conforming to this protocol so the SDK
 * can discover which adapters are installed and include their versions in the
 * config request. The server uses this to detect mismatches between dashboard
 * configuration and the adapters actually bundled in the app.
 */
@protocol CLXAdapterMetadataProvider <NSObject>

@property (nonatomic, copy, readonly) NSString *adapterVersion;
@property (nonatomic, copy, readonly) NSString *networkSdkVersion;

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
