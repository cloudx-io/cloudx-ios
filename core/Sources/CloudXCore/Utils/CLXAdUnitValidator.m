//
// CLXAdUnitValidator.m
// CloudXCore
//
// Validates ad unit configuration and provides detailed error messages
//

#import <CloudXCore/CLXAdUnitValidator.h>
#import <CloudXCore/CLXLogger.h>

#pragma mark - CLXAdUnitValidationResult

@interface CLXAdUnitValidationResult ()
@property (nonatomic, readwrite, nullable) CLXSDKConfigAdUnit *adUnit;
@property (nonatomic, readwrite, nullable) CLXError *error;
@end

@implementation CLXAdUnitValidationResult

+ (instancetype)successWithAdUnit:(CLXSDKConfigAdUnit *)adUnit {
    CLXAdUnitValidationResult *result = [[CLXAdUnitValidationResult alloc] init];
    result.adUnit = adUnit;
    return result;
}

+ (instancetype)failureWithError:(CLXError *)error {
    CLXAdUnitValidationResult *result = [[CLXAdUnitValidationResult alloc] init];
    result.error = error;
    return result;
}

- (BOOL)isSuccess {
    return self.adUnit != nil && self.error == nil;
}

@end

#pragma mark - CLXAdUnitValidator

@implementation CLXAdUnitValidator

+ (CLXAdUnitValidationResult *)validateInterstitialAdUnit:(NSString *)adUnitId
                                                  adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits {
    return [self validateAdUnit:adUnitId
                        adUnits:adUnits
                 expectedAdType:SDKConfigAdTypeInterstitial];
}

+ (CLXAdUnitValidationResult *)validateRewardedAdUnit:(NSString *)adUnitId
                                              adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits {
    return [self validateAdUnit:adUnitId
                        adUnits:adUnits
                 expectedAdType:SDKConfigAdTypeRewarded];
}

+ (CLXAdUnitValidationResult *)validateBannerAdUnit:(NSString *)adUnitId
                                            adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits {
    return [self validateAdUnit:adUnitId
                        adUnits:adUnits
                 expectedAdType:SDKConfigAdTypeBanner];
}

+ (CLXAdUnitValidationResult *)validateMRECAdUnit:(NSString *)adUnitId
                                          adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits {
    return [self validateAdUnit:adUnitId
                        adUnits:adUnits
                 expectedAdType:SDKConfigAdTypeMrec];
}

+ (CLXAdUnitValidationResult *)validateNativeAdUnit:(NSString *)adUnitId
                                            adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits {
    // Native ads don't have a specific type - just validate existence
    CLXSDKConfigAdUnit *foundAdUnit = adUnits[adUnitId];
    
    if (!foundAdUnit) {
        CLXError *error = [self createAdUnitNotFoundError:adUnitId
                                                  adUnits:adUnits];
        return [CLXAdUnitValidationResult failureWithError:error];
    }
    
    return [CLXAdUnitValidationResult successWithAdUnit:foundAdUnit];
}

#pragma mark - Private Methods

+ (CLXAdUnitValidationResult *)validateAdUnit:(NSString *)adUnitId
                                      adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits
                               expectedAdType:(SDKConfigAdType)expectedAdType {
    CLXSDKConfigAdUnit *foundAdUnit = adUnits[adUnitId];
    
    // Check if ad unit exists
    if (!foundAdUnit) {
        CLXError *error = [self createAdUnitNotFoundError:adUnitId
                                                  adUnits:adUnits];
        return [CLXAdUnitValidationResult failureWithError:error];
    }
    
    // Check if ad unit has correct ad type
    if (foundAdUnit.type != expectedAdType) {
        CLXError *error = [self createWrongAdTypeError:adUnitId
                                           foundAdUnit:foundAdUnit
                                        expectedAdType:expectedAdType];
        return [CLXAdUnitValidationResult failureWithError:error];
    }
    
    return [CLXAdUnitValidationResult successWithAdUnit:foundAdUnit];
}

+ (CLXError *)createAdUnitNotFoundError:(NSString *)adUnitId
                                adUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits {
    NSString *availableAdUnitsString = [self formatAvailableAdUnits:adUnits];
    
    NSString *description = [NSString stringWithFormat:
                             @"Ad unit '%@' not found in SDK configuration. Available ad units: [%@].",
                             adUnitId,
                             availableAdUnitsString];
    
    return [CLXError errorWithCode:CLXErrorCodeInvalidAdUnit
                       description:description];
}

+ (CLXError *)createWrongAdTypeError:(NSString *)adUnitId
                         foundAdUnit:(CLXSDKConfigAdUnit *)foundAdUnit
                      expectedAdType:(SDKConfigAdType)expectedAdType {
    NSString *expectedTypeString = [self stringForAdType:expectedAdType];
    NSString *actualTypeString = [self stringForAdType:foundAdUnit.type];
    
    NSString *description = [NSString stringWithFormat:
                             @"Ad unit '%@' exists but has wrong ad type. Requested: %@, Actual: %@.",
                             adUnitId,
                             expectedTypeString,
                             actualTypeString];
    
    return [CLXError errorWithCode:CLXErrorCodeInvalidAdUnit
                       description:description];
}

+ (NSString *)formatAvailableAdUnits:(NSDictionary<NSString *, CLXSDKConfigAdUnit *> *)adUnits {
    if (!adUnits || adUnits.count == 0) {
        return @"none";
    }
    
    NSArray<NSString *> *sortedNames = [[adUnits allKeys] sortedArrayUsingSelector:@selector(compare:)];
    return [sortedNames componentsJoinedByString:@", "];
}

+ (NSString *)stringForAdType:(SDKConfigAdType)type {
    switch (type) {
        case SDKConfigAdTypeBanner:
            return @"Banner";
        case SDKConfigAdTypeMrec:
            return @"MREC";
        case SDKConfigAdTypeInterstitial:
            return @"Interstitial";
        case SDKConfigAdTypeRewarded:
            return @"Rewarded";
        case SDKConfigAdTypeUnknown:
        default:
            return @"Unknown";
    }
}

@end
