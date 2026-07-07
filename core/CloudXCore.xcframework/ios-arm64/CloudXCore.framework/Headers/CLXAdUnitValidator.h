//
// CLXAdUnitValidator.h
// CloudXCore
//
// Validates ad unit configuration and provides detailed error messages
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXError.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Result of ad unit validation containing either a valid ad unit or an error
 */
@interface CLXAdUnitValidationResult : NSObject

/**
 * The validated ad unit if validation succeeded, nil otherwise
 */
@property (nonatomic, readonly, nullable) CLXSDKConfigAdUnit *adUnit;

/**
 * The error if validation failed, nil otherwise
 */
@property (nonatomic, readonly, nullable) CLXError *error;

/**
 * Whether the validation was successful
 */
@property (nonatomic, readonly) BOOL isSuccess;

+ (instancetype)successWithAdUnit:(CLXSDKConfigAdUnit *)adUnit;
+ (instancetype)failureWithError:(CLXError *)error;

@end

/**
 * Validates ad unit configuration and provides detailed error messages.
 *
 * This validator mirrors Android's AdUnitValidator behavior, providing:
 * - Detailed error messages when an ad unit is not found (lists available ad units)
 * - Detailed error messages when an ad unit has the wrong ad type (shows expected vs actual)
 */
@interface CLXAdUnitValidator : NSObject

/**
 * Validates that an interstitial ad unit exists and has the correct type.
 * @param adUnitId The ID of the ad unit to validate
 * @param adUnits Dictionary of available ad units (name -> CLXSDKConfigAdUnit)
 * @return Validation result with ad unit or detailed error
 */
+ (CLXAdUnitValidationResult *)validateInterstitialAdUnit:(NSString *)adUnitId
                                                  adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits;

/**
 * Validates that a rewarded ad unit exists and has the correct type.
 * @param adUnitId The ID of the ad unit to validate
 * @param adUnits Dictionary of available ad units (name -> CLXSDKConfigAdUnit)
 * @return Validation result with ad unit or detailed error
 */
+ (CLXAdUnitValidationResult *)validateRewardedAdUnit:(NSString *)adUnitId
                                              adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits;

/**
 * Validates that an app open ad unit exists and has the correct type.
 * @param adUnitId The ID of the ad unit to validate
 * @param adUnits Dictionary of available ad units (name -> CLXSDKConfigAdUnit)
 * @return Validation result with ad unit or detailed error
 */
+ (CLXAdUnitValidationResult *)validateAppOpenAdUnit:(NSString *)adUnitId
                                             adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits;

/**
 * Validates that a banner ad unit exists and has the correct type.
 * @param adUnitId The ID of the ad unit to validate
 * @param adUnits Dictionary of available ad units (name -> CLXSDKConfigAdUnit)
 * @return Validation result with ad unit or detailed error
 */
+ (CLXAdUnitValidationResult *)validateBannerAdUnit:(NSString *)adUnitId
                                            adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits;

/**
 * Validates that an MREC ad unit exists and has the correct type.
 * @param adUnitId The ID of the ad unit to validate
 * @param adUnits Dictionary of available ad units (name -> CLXSDKConfigAdUnit)
 * @return Validation result with ad unit or detailed error
 */
+ (CLXAdUnitValidationResult *)validateMRECAdUnit:(NSString *)adUnitId
                                          adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits;

/**
 * Validates that a native ad unit exists. Native ads don't have a specific type in the config,
 * so this only validates existence.
 * @param adUnitId The ID of the ad unit to validate
 * @param adUnits Dictionary of available ad units (name -> CLXSDKConfigAdUnit)
 * @return Validation result with ad unit or detailed error
 */
+ (CLXAdUnitValidationResult *)validateNativeAdUnit:(NSString *)adUnitId
                                            adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits;

/**
 * Returns a human-readable string for the ad type.
 * @param type The SDK config ad type
 * @return Human-readable string (e.g., "Banner", "Interstitial", "Rewarded", "MREC")
 */
+ (NSString *)stringForAdType:(SDKConfigAdType)type;

@end

NS_ASSUME_NONNULL_END
