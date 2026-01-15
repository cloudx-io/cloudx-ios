//
// CLXPlacementValidator.h
// CloudXCore
//
// Validates placement configuration and provides detailed error messages
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Result of placement validation containing either a valid placement or an error
 */
@interface CLXPlacementValidationResult : NSObject

/**
 * The validated placement if validation succeeded, nil otherwise
 */
@property (nonatomic, readonly, nullable) CLXSDKConfigPlacement *placement;

/**
 * The error if validation failed, nil otherwise
 */
@property (nonatomic, readonly, nullable) CLXError *error;

/**
 * Whether the validation was successful
 */
@property (nonatomic, readonly) BOOL isSuccess;

+ (instancetype)successWithPlacement:(CLXSDKConfigPlacement *)placement;
+ (instancetype)failureWithError:(CLXError *)error;

@end

/**
 * Validates placement configuration and provides detailed error messages.
 *
 * This validator mirrors Android's PlacementValidator behavior, providing:
 * - Detailed error messages when a placement is not found (lists available placements)
 * - Detailed error messages when a placement has the wrong ad type (shows expected vs actual)
 */
@interface CLXPlacementValidator : NSObject

/**
 * Validates that an interstitial placement exists and has the correct type.
 * @param placementName The name of the placement to validate
 * @param placements Dictionary of available placements (name -> CLXSDKConfigPlacement)
 * @return Validation result with placement or detailed error
 */
+ (CLXPlacementValidationResult *)validateInterstitialPlacement:(NSString *)placementName
                                                     placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements;

/**
 * Validates that a rewarded placement exists and has the correct type.
 * @param placementName The name of the placement to validate
 * @param placements Dictionary of available placements (name -> CLXSDKConfigPlacement)
 * @return Validation result with placement or detailed error
 */
+ (CLXPlacementValidationResult *)validateRewardedPlacement:(NSString *)placementName
                                                 placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements;

/**
 * Validates that a banner placement exists and has the correct type.
 * @param placementName The name of the placement to validate
 * @param placements Dictionary of available placements (name -> CLXSDKConfigPlacement)
 * @return Validation result with placement or detailed error
 */
+ (CLXPlacementValidationResult *)validateBannerPlacement:(NSString *)placementName
                                               placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements;

/**
 * Validates that an MREC placement exists and has the correct type.
 * @param placementName The name of the placement to validate
 * @param placements Dictionary of available placements (name -> CLXSDKConfigPlacement)
 * @return Validation result with placement or detailed error
 */
+ (CLXPlacementValidationResult *)validateMRECPlacement:(NSString *)placementName
                                             placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements;

/**
 * Validates that a native placement exists. Native ads don't have a specific type in the config,
 * so this only validates existence.
 * @param placementName The name of the placement to validate
 * @param placements Dictionary of available placements (name -> CLXSDKConfigPlacement)
 * @return Validation result with placement or detailed error
 */
+ (CLXPlacementValidationResult *)validateNativePlacement:(NSString *)placementName
                                               placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements;

/**
 * Returns a human-readable string for the ad type.
 * @param type The SDK config ad type
 * @return Human-readable string (e.g., "Banner", "Interstitial", "Rewarded", "MREC")
 */
+ (NSString *)stringForAdType:(SDKConfigAdType)type;

@end

NS_ASSUME_NONNULL_END
