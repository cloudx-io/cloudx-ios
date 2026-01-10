//
//  CLXRendererInitializer.m
//  CloudXRenderer
//
//  Renderer adapter initializer implementation for CloudX Renderer
//  
//  This class provides initialization management for the Renderer including:
//  - Synchronous and asynchronous initialization methods
//  - Initialization state tracking and management
//  - Configuration validation and processing
//  - Factory method for instance creation
//  - Comprehensive logging for debugging
//  - Error handling and completion callbacks
//

#import "CLXRendererInitializer.h"
#import <CloudXCore/CLXLogger.h>

/**
 * CLXRendererInitializer - Initialization manager for CloudX Renderer
 * 
 * Manages the initialization state and process for the Renderer.
 * Since the Renderer is rendering-only, minimal initialization is required.
 */
@implementation CLXRendererInitializer

/**
 * Static flag to track initialization state
 * Ensures the adapter is only initialized once per application lifecycle
 */
static BOOL isInitialized = NO;

/**
 * Check if the Renderer has been initialized
 * 
 * Returns the current initialization state. Since the Renderer
 * is rendering-only, this is primarily for consistency with other adapters.
 * 
 * @return YES if adapter has been initialized, NO otherwise
 */
+ (BOOL)isInitialized {
    return isInitialized;
}

/**
 * Create a new instance of CLXRendererInitializer
 * 
 * Factory method for creating initializer instances.
 * Used by the adapter resolution system to instantiate initializers.
 * 
 * @return New CLXRendererInitializer instance
 */
+ (instancetype)createInstance {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXRendererInitializer"];
    [logger info:@"[ CloudXRendererInitializer createInstance called"];
    
    CLXRendererInitializer *instance = [[CLXRendererInitializer alloc] init];
    return instance;
}

/**
 * Initialize the Renderer synchronously
 * 
 * Performs synchronous initialization of the Renderer.
 * Since the adapter is rendering-only, minimal setup is required.
 * 
 * @param config Bidder configuration (optional for Renderer)
 * @return YES if initialization was successful
 */
- (BOOL)initializeWithConfig:(CLXBidderConfig *)config {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXRendererInitializer"];
    [logger debug:@"[INIT-SYNC] CloudXRendererInitializer synchronous initialization started"];
    
    // Renderer is rendering-only, no special initialization needed
    [logger info:@"Synchronous initialization completed successfully"];
    
    return YES;
}

/**
 * Initialize the Renderer asynchronously
 * 
 * Performs asynchronous initialization of the Renderer.
 * Since the adapter is rendering-only, initialization completes immediately.
 * Calls the completion handler with success result.
 * 
 * @param config Bidder configuration (optional for Renderer)
 * @param completion Completion block called with initialization result
 */
- (void)initializeWithConfig:(nullable CLXBidderConfig *)config testMode:(BOOL)testMode completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXRendererInitializer"];
    [logger debug:[NSString stringWithFormat:@"[INIT-ASYNC] CloudXRendererInitializer async initialization started (testMode: %@)", testMode ? @"YES" : @"NO"]];
    
    // Renderer is rendering-only, no special initialization needed
    // Set initialization state to true
    isInitialized = YES;
    
    // Call completion handler with success result
    if (completion) {
        completion(YES, nil);
    }
    
    [logger info:@"Async initialization completed successfully"];
}

@end 