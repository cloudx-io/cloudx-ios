//
// CloudXCoreError.h
// CloudXCore
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudX SDK error codes - matches Swift CloudXError enum exactly
 */
typedef NS_ENUM(NSInteger, CloudXCoreErrorCode) {
    // SDK initialization errors
    CloudXCoreErrorCodeFailToInitSDK = 100,
    CloudXCoreErrorCodeSDKInitialisationInProgress = 101,
    CloudXCoreErrorCodeSDKInitializedWithoutAdapters = 102,
    CloudXCoreErrorCodeNoBiddersFound = 103,
    
    // General ad errors
    CloudXCoreErrorCodeGeneralAdError = 200,
    CloudXCoreErrorCodeBannerViewError = 201,
    CloudXCoreErrorCodeNativeViewError = 202,
    
    // Placement and ad loading errors
    CloudXCoreErrorCodeInvalidPlacement = 2002,
    CloudXCoreErrorCodeNoAdsLoaded = 2003,
    CloudXCoreErrorCodeNoBidTokenSource = 2004
};

/**
 * CloudX SDK error domain
 */
extern NSString * const CloudXCoreErrorDomain;

/**
 * CloudX SDK error class - subclass of NSError to match Swift enum behavior
 */
@interface CloudXCoreError : NSError

/**
 * Creates an error with the specified CloudX error code
 * @param code The CloudX error code
 * @return A new CloudXCoreError instance
 */
+ (instancetype)errorWithCode:(CloudXCoreErrorCode)code;

/**
 * Creates an error with the specified CloudX error code and user info
 * @param code The CloudX error code
 * @param userInfo Additional user info dictionary
 * @return A new CloudXCoreError instance
 */
+ (instancetype)errorWithCode:(CloudXCoreErrorCode)code userInfo:(nullable NSDictionary *)userInfo;

/**
 * Initializes an error with the specified CloudX error code
 * @param code The CloudX error code
 * @return An initialized CloudXCoreError instance
 */
- (instancetype)initWithCode:(CloudXCoreErrorCode)code;

/**
 * Initializes an error with the specified CloudX error code and user info
 * @param code The CloudX error code
 * @param userInfo Additional user info dictionary
 * @return An initialized CloudXCoreError instance
 */
- (instancetype)initWithCode:(CloudXCoreErrorCode)code userInfo:(nullable NSDictionary *)userInfo;

@end

NS_ASSUME_NONNULL_END 