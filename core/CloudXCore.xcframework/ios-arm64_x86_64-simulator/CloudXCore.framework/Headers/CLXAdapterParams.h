/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

CLX_PUBLIC_ADAPTER
@interface CLXAdapterParams : NSObject

@property (nonatomic, strong, readonly) id<CLXAdapterLogger> logger;
@property (nonatomic, copy, readonly) NSString *sdkVersion;
@property (nonatomic, assign, readonly) NSInteger sdkVersionCode;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *serverExtras;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *localExtras;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
