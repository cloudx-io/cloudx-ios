/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterPrivacyHandler.h
 * @brief Abstract base class for adapter-specific privacy settings handling
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

@class CLXAdapterPrivacySettings;

NS_ASSUME_NONNULL_BEGIN

/**
 * Abstract base class for adapter privacy handlers.
 *
 * Subclass MUST override @c -updatePrivacySettings:.
 * The CLXAdapterPrivacyForwarder discovers handlers via NSClassFromString
 * and calls @c -updatePrivacySettings: when settings change.
 */
CLX_PUBLIC_ADAPTER
@interface CLXAdapterPrivacyHandler : NSObject

- (void)updatePrivacySettings:(CLXAdapterPrivacySettings *)settings;

@end

NS_ASSUME_NONNULL_END
