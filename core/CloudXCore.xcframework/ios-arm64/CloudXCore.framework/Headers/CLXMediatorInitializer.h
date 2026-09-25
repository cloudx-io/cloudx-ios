/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>
#import <CloudXCore/CLXMediatorParams.h>
#import <CloudXCore/CLXMediatorTypes.h>

NS_ASSUME_NONNULL_BEGIN

/** Initializes the third-party SDK used by a mediator module. */
CLX_PUBLIC_MEDIATOR
@interface CLXMediatorInitializer : NSObject

+ (instancetype)createInstance;

/// The thread on which Core calls initializeWithParams:. Defaults to main.
@property (nonatomic, assign, readonly) CLXMediatorThreadRequirement initializationThreadRequirement;

/**
 * Starts initialization.
 *
 * The module must call params.completion exactly once. Core may impose an
 * initialization timeout and ignore a completion after the initialization
 * attempt becomes stale. Timeout duration and cancellation are Core policy,
 * not part of the module contract.
 */
- (void)initializeWithParams:(CLXMediatorInitializationParams *)params;

@end

NS_ASSUME_NONNULL_END
