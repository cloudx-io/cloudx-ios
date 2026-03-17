//
//  CLXBidResponseSwizzler.h
//  CloudXObjCRemotePods
//
//  Swizzles the bid network service to log full bid responses
//  for QA inspection. This is a demo app-only feature.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXSimulatedErrorType) {
    CLXSimulatedErrorTypeNone = 0,
    CLXSimulatedErrorTypeHTTP400,
    CLXSimulatedErrorTypeHTTP500,
    CLXSimulatedErrorTypeNoFill,
};

/**
 * Swizzler for logging full bid responses and simulating errors.
 * 
 * When enabled via the "Print Full Bid Response" setting, this class
 * intercepts bid responses and logs them to the Xcode console.
 *
 * When a simulated error is set, the next bid request will short-circuit
 * and return the fabricated error instead of hitting the network.
 * The simulation auto-resets after firing once.
 * 
 * This is a demo app-only feature - NOT exposed in SDK logs.
 */
@interface CLXBidResponseSwizzler : NSObject

/**
 * Enable swizzling to intercept bid responses.
 * Call this early in app startup (e.g., in AppDelegate).
 */
+ (void)enableSwizzling;

/**
 * Disable swizzling and restore original behavior.
 */
+ (void)disableSwizzling;

/**
 * Check if swizzling is currently enabled.
 */
+ (BOOL)isSwizzlingEnabled;

/**
 * Set the simulated error type for the next bid request.
 * Automatically enables swizzling if not already active.
 * Fires once and resets to CLXSimulatedErrorTypeNone.
 */
+ (void)setSimulatedErrorType:(CLXSimulatedErrorType)errorType;

/**
 * Returns the currently armed simulated error type.
 */
+ (CLXSimulatedErrorType)simulatedErrorType;

@end

NS_ASSUME_NONNULL_END
