/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterPrivacyHandler.h
 * @brief Abstract base class for adapter-specific privacy params handling
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

@class CLXAdapterPrivacyParams;

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for adapter privacy handlers.
 *
 * Subclass MUST override @c -updatePrivacySettings:.
 * The CLXAdapterPrivacyForwarder discovers handlers via NSClassFromString
 * and calls @c -updatePrivacySettings: when privacy state changes.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterPrivacyHandler : NSObject

- (void)updatePrivacySettings:(CLXAdapterPrivacyParams *)params;

@end

NS_ASSUME_NONNULL_END
