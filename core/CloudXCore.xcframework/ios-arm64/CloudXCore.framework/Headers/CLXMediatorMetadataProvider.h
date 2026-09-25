/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

#define CLXMediatorAPIVersion 1

/**
 * Supplies version metadata for an installed mediator module.
 *
 * V1 modules must override every required property. The base implementations
 * fail closed so an incomplete module cannot pass a compatibility check.
 */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorMetadataProvider : NSObject

@property (nonatomic, copy, readonly) NSString *mediatorModuleVersion;
@property (nonatomic, copy, readonly) NSString *mediatorSDKVersion;
@property (nonatomic, copy, readonly) NSString *minimumCloudXCoreVersion;
/// Comparable version code: major * 1,000,000 + minor * 1,000 + patch.
@property (nonatomic, assign, readonly) NSInteger minimumCloudXCoreVersionCode;
@property (nonatomic, assign, readonly) NSInteger mediatorAPIVersion;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *extras;

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END
