/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Typed adapter network identifier — single source of truth for known ad networks.
///
/// Concrete network identifier constants (e.g. `CLXAdNetworkMeta`) are declared
/// in `CLXAdNetwork+Internal.h`. They are referenced only by CloudXCore's own
/// registry/dispatch code and are intentionally hidden in the shipped binary.
/// Adapter authors should not need them — use the metadata provider machinery
/// in `CLXAdapterMetadataProvider` instead.
typedef NSString *CLXAdNetwork NS_STRING_ENUM;

NS_ASSUME_NONNULL_END
