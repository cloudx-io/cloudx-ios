/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXBidResponse+Internal.h
 * @brief Internal userInfo key used by bid response parsing.
 * @discussion `CLXNonBidDetailsKey` is referenced only by CloudXCore's own
 *             bid response parsing code. It is intentionally hidden in the
 *             shipped binary.
 */

#import <CloudXCore/CLXBidResponse.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CLXNonBidDetailsKey;

NS_ASSUME_NONNULL_END
