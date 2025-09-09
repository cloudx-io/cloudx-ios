//
//  CLXUserDefaultsTestHelper.h
//  CloudXCoreTests
//
//  Shared utility for User Defaults test isolation
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility class for ensuring proper test isolation in User Defaults tests.
 * 
 * CloudXCore uses 15+ unprefixed User Defaults keys that can cause test contamination
 * when running the full test suite. This helper ensures all tests start with a clean slate
 * while still using [NSUserDefaults standardUserDefaults] to replicate real-world collision scenarios.
 * 
 * IMPORTANT: Tests intentionally use standardUserDefaults (not injected instances) to demonstrate
 * actual collision risk that would occur in production environments.
 */
@interface CLXUserDefaultsTestHelper : NSObject

/**
 * Clears all User Defaults keys that CloudXCore uses to ensure test isolation.
 * 
 * This method clears both:
 * - The actual unprefixed keys CloudXCore currently uses (e.g., "appKey", "sessionIDKey")
 * - Any prefixed keys that might be used in future implementations
 * 
 * Call this in both setUp and tearDown methods of User Defaults tests.
 */
+ (void)clearAllCloudXCoreUserDefaultsKeys;

/**
 * Returns an array of all the unprefixed User Defaults keys that CloudXCore uses.
 * Useful for debugging test isolation issues.
 */
+ (NSArray<NSString *> *)allUnprefixedKeys;

@end

NS_ASSUME_NONNULL_END