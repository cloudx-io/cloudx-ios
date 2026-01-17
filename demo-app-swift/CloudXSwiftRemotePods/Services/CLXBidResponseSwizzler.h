//
//  CLXBidResponseSwizzler.h
//  CloudXSwiftRemotePods
//
//  Swizzles the bid network service to log full bid responses
//  for QA inspection. This is a demo app-only feature.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Swizzler for logging full bid responses from the network.
 * 
 * When enabled via the "Print Full Bid Response" setting, this class
 * intercepts bid responses and logs them to the Xcode console.
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

@end

NS_ASSUME_NONNULL_END
