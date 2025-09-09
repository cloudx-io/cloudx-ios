//
//  CLXPrebidInitializer.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 adapter initializer implementation for CloudX Prebid Adapter
//  
//  This class provides initialization management for the Prebid adapter including:
//  - Synchronous and asynchronous initialization methods
//  - Initialization state tracking and management
//  - Configuration validation and processing
//  - Factory method for instance creation
//  - Comprehensive logging for debugging
//  - Error handling and completion callbacks
//

#import "CLXPrebidInitializer.h"
#import <CloudXCore/CLXLogger.h>

/**
 * CLXPrebidInitializer - Initialization manager for CloudX Prebid Adapter
 * 
 * Manages the initialization state and process for the Prebid adapter.
 * Since the Prebid adapter is rendering-only, minimal initialization is required.
 */
@implementation CLXPrebidInitializer

/**
 * Static flag to track initialization state
 * Ensures the adapter is only initialized once per application lifecycle
 */
static BOOL isInitialized = NO;

/**
 * Check if the Prebid adapter has been initialized
 * 
 * Returns the current initialization state. Since the Prebid adapter
 * is rendering-only, this is primarily for consistency with other adapters.
 * 
 * @return YES if adapter has been initialized, NO otherwise
 */
+ (BOOL)isInitialized {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXPrebidInitializer"];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT-CHECK] isInitialized called, current state: %@", isInitialized ? @"YES" : @"NO"]];
    return isInitialized;
}

/**
 * Create a new instance of CLXPrebidInitializer
 * 
 * Factory method for creating initializer instances.
 * Used by the adapter resolution system to instantiate initializers.
 * 
 * @return New CLXPrebidInitializer instance
 */
+ (instancetype)createInstance {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXPrebidInitializer"];
    [logger info:@"🏭 [FACTORY] CloudXPrebidInitializer createInstance called"];
    
    CLXPrebidInitializer *instance = [[CLXPrebidInitializer alloc] init];
    [logger info:[NSString stringWithFormat:@"✅ [FACTORY] CloudXPrebidInitializer instance created: %p", instance]];
    return instance;
}

/**
 * Initialize the Prebid adapter synchronously
 * 
 * Performs synchronous initialization of the Prebid adapter.
 * Since the adapter is rendering-only, minimal setup is required.
 * 
 * @param config Bidder configuration (optional for Prebid adapter)
 * @return YES if initialization was successful
 */
- (BOOL)initializeWithConfig:(CLXBidderConfig *)config {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXPrebidInitializer"];
    [logger info:@"🚀 [INIT-SYNC] CloudXPrebidInitializer synchronous initialization started"];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT-SYNC] Config provided: %@", config ? @"YES" : @"NO"]];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT-SYNC] Config class: %@", config ? NSStringFromClass([config class]) : @"N/A"]];
    
    // Prebid adapter is rendering-only, no special initialization needed
    [logger info:@"✅ [INIT-SYNC] Prebid adapter is rendering-only - no special initialization required"];
    [logger info:@"🎯 [INIT-SYNC] Synchronous initialization completed successfully"];
    
    return YES;
}

/**
 * Initialize the Prebid adapter asynchronously
 * 
 * Performs asynchronous initialization of the Prebid adapter.
 * Since the adapter is rendering-only, initialization completes immediately.
 * Calls the completion handler with success result.
 * 
 * @param config Bidder configuration (optional for Prebid adapter)
 * @param completion Completion block called with initialization result
 */
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXPrebidInitializer"];
    [logger info:@"🚀 [INIT-ASYNC] CloudXPrebidInitializer async initialization started"];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT-ASYNC] Config provided: %@", config ? @"YES" : @"NO"]];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT-ASYNC] Config class: %@", config ? NSStringFromClass([config class]) : @"N/A"]];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT-ASYNC] Completion handler: %@", completion ? @"Present" : @"nil"]];
    [logger debug:[NSString stringWithFormat:@"📊 [INIT-ASYNC] Previous initialization state: %@", isInitialized ? @"Already initialized" : @"Not initialized"]];
    
    // Prebid adapter is rendering-only, no special initialization needed
    [logger info:@"✅ [INIT-ASYNC] Prebid adapter is rendering-only - no special initialization required"];
    
    // Set initialization state to true
    isInitialized = YES;
    [logger info:@"📊 [INIT-ASYNC] Initialization state set to: YES"];
    
    // Call completion handler with success result
    if (completion) {
        [logger info:@"📞 [INIT-ASYNC] Calling completion handler with success=YES"];
        completion(YES, nil);
        [logger debug:@"✅ [INIT-ASYNC] Completion handler call completed"];
    } else {
        [logger info:@"⚠️ [INIT-ASYNC] No completion handler provided - success result will not be reported"];
    }
    
    [logger info:@"🎯 [INIT-ASYNC] Async initialization completed successfully"];
}

@end 