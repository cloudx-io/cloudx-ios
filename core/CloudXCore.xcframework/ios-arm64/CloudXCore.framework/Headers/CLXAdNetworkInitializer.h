/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXBidderConfig;

/// Abstract base class for ad network initializers.
/// Subclass MUST override @c -initializeWithConfig:testMode:completion:.
CLX_PUBLIC_ADAPTER
@interface CLXAdNetworkInitializer : NSObject

+ (instancetype)createInstance;

/// CloudX SDK calls this method to initialize the ad network SDK.
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
