/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Version metadata for an installed adapter, collected before the config request.
 */
@interface CLXAdapterMetadata : NSObject

@property (nonatomic, copy, readonly) NSString *network;
@property (nonatomic, copy, readonly) NSString *adapterVersion;
@property (nonatomic, copy, readonly) NSString *networkSdkVersion;

- (instancetype)initWithNetwork:(NSString *)network
                 adapterVersion:(NSString *)adapterVersion
              networkSdkVersion:(NSString *)networkSdkVersion;

- (NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
