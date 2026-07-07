/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/// Adapter-facing logging contract. Core supplies an implementation through
/// adapter params without exposing the SDK's concrete logger type.
@protocol CLXAdapterLogger <NSObject>

- (void)verbose:(NSString *)message;
- (void)debug:(NSString *)message;
- (void)info:(NSString *)message;
- (void)warn:(NSString *)message;
- (void)error:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
