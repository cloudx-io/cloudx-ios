/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXMediatorParams.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Privacy values that Core passes to a mediator module.
 *
 * A nil value is unknown. A module must not overwrite its third-party SDK's
 * corresponding privacy state when a value is unknown.
 */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorPrivacyParams : CLXMediatorParams

@property (nonatomic, copy, readonly, nullable) NSNumber *hasUserConsent;
@property (nonatomic, copy, readonly, nullable) NSNumber *isDoNotSell;
@property (nonatomic, copy, readonly, nullable) NSNumber *manualHasUserConsent;
@property (nonatomic, copy, readonly, nullable) NSNumber *manualIsDoNotSell;

@end

/**
 * Receives privacy updates for one mediator module.
 *
 * The base implementation intentionally does nothing so an optional handler
 * cannot crash a host app. A module that exposes this handler must override
 * the method and apply all known values before it initializes its SDK.
 */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorPrivacyHandler : NSObject

+ (instancetype)createInstance;
- (void)updatePrivacySettingsWithParams:(CLXMediatorPrivacyParams *)params;

@end

NS_ASSUME_NONNULL_END
