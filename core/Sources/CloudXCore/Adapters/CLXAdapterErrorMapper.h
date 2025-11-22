/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdapterErrorMapper.h
 * @brief Standardized error mapping for adapter factory validation failures
 *
 * This utility maps adapter validation failures to appropriate CLXErrorCode values
 * with descriptive messages. Introduced in v1.3.0 as part of the factory pattern
 * refactor to align iOS with Android behavior.
 *
 * @since 1.3.0
 */

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Enumeration of adapter validation error types
 */
typedef NS_ENUM(NSInteger, CLXAdapterValidationError) {
    /// Placement ID is nil, empty, or invalid format
    CLXAdapterValidationErrorInvalidPlacementID = 1,
    
    /// Bid payload is malformed or failed validation
    CLXAdapterValidationErrorInvalidBidPayload = 2,
    
    /// Third-party adapter SDK is not initialized
    CLXAdapterValidationErrorSDKNotInitialized = 3,
    
    /// Ad format not supported by this adapter
    CLXAdapterValidationErrorUnsupportedAdFormat = 4,
    
    /// Required delegate parameter is nil
    CLXAdapterValidationErrorMissingDelegate = 5,
    
    /// Required view controller parameter is nil
    CLXAdapterValidationErrorMissingViewController = 6,
    
    /// Required bid ID parameter is nil or empty
    CLXAdapterValidationErrorMissingBidID = 7,
};

/**
 * Utility class for mapping adapter validation errors to CLXError objects
 */
@interface CLXAdapterErrorMapper : NSObject

/**
 * Maps an adapter validation error to a CLXError with appropriate code and message
 *
 * @param validationError The type of validation failure
 * @param context Description of the ad format (e.g., "banner", "interstitial")
 * @param placementID The placement ID that failed validation (if applicable)
 * @param network The ad network name (e.g., "Meta", "Vungle")
 * @return A CLXError object with mapped error code and descriptive message
 *
 * @discussion This method ensures consistent error reporting across all adapters.
 *             Error messages include network name for easier debugging.
 */
+ (NSError *)errorForValidationFailure:(CLXAdapterValidationError)validationError
                               context:(NSString *)context
                           placementID:(nullable NSString *)placementID
                               network:(NSString *)network;

/**
 * Creates an error for invalid placement ID
 *
 * @param network The ad network name
 * @param context The ad format context
 * @param placementID The invalid placement ID (may be nil)
 * @return A CLXError with CLXErrorCodeInvalidAdUnitID
 */
+ (NSError *)invalidPlacementIDErrorForNetwork:(NSString *)network
                                       context:(NSString *)context
                                   placementID:(nullable NSString *)placementID;

/**
 * Creates an error for SDK not initialized
 *
 * @param network The ad network name
 * @param context The ad format context
 * @return A CLXError with CLXErrorCodeNotInitialized
 */
+ (NSError *)sdkNotInitializedErrorForNetwork:(NSString *)network
                                      context:(NSString *)context;

/**
 * Creates an error for unsupported ad format
 *
 * @param network The ad network name
 * @param context The ad format context
 * @param formatInfo Additional format information (e.g., banner size)
 * @return A CLXError with CLXErrorCodeUnsupportedAdFormat
 */
+ (NSError *)unsupportedFormatErrorForNetwork:(NSString *)network
                                      context:(NSString *)context
                                   formatInfo:(nullable NSString *)formatInfo;

@end

NS_ASSUME_NONNULL_END

