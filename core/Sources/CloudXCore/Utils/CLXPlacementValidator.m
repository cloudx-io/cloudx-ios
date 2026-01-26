//
// CLXPlacementValidator.m
// CloudXCore
//
// Validates placement configuration and provides detailed error messages
//

#import <CloudXCore/CLXPlacementValidator.h>
#import <CloudXCore/CLXLogger.h>

#pragma mark - CLXPlacementValidationResult

@interface CLXPlacementValidationResult ()
@property (nonatomic, readwrite, nullable) CLXSDKConfigPlacement *placement;
@property (nonatomic, readwrite, nullable) CLXError *error;
@end

@implementation CLXPlacementValidationResult

+ (instancetype)successWithPlacement:(CLXSDKConfigPlacement *)placement {
    CLXPlacementValidationResult *result = [[CLXPlacementValidationResult alloc] init];
    result.placement = placement;
    return result;
}

+ (instancetype)failureWithError:(CLXError *)error {
    CLXPlacementValidationResult *result = [[CLXPlacementValidationResult alloc] init];
    result.error = error;
    return result;
}

- (BOOL)isSuccess {
    return self.placement != nil && self.error == nil;
}

@end

#pragma mark - CLXPlacementValidator

@implementation CLXPlacementValidator

+ (CLXPlacementValidationResult *)validateInterstitialPlacement:(NSString *)placementName
                                                     placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements {
    return [self validatePlacement:placementName
                        placements:placements
                   expectedAdType:SDKConfigAdTypeInterstitial];
}

+ (CLXPlacementValidationResult *)validateRewardedPlacement:(NSString *)placementName
                                                 placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements {
    return [self validatePlacement:placementName
                        placements:placements
                   expectedAdType:SDKConfigAdTypeRewarded];
}

+ (CLXPlacementValidationResult *)validateBannerPlacement:(NSString *)placementName
                                               placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements {
    return [self validatePlacement:placementName
                        placements:placements
                   expectedAdType:SDKConfigAdTypeBanner];
}

+ (CLXPlacementValidationResult *)validateMRECPlacement:(NSString *)placementName
                                             placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements {
    return [self validatePlacement:placementName
                        placements:placements
                   expectedAdType:SDKConfigAdTypeMrec];
}

+ (CLXPlacementValidationResult *)validateNativePlacement:(NSString *)placementName
                                               placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements {
    // Native ads don't have a specific type - just validate existence
    CLXSDKConfigPlacement *foundPlacement = placements[placementName];
    
    if (!foundPlacement) {
        CLXError *error = [self createPlacementNotFoundError:placementName
                                                  placements:placements];
        return [CLXPlacementValidationResult failureWithError:error];
    }
    
    return [CLXPlacementValidationResult successWithPlacement:foundPlacement];
}

#pragma mark - Private Methods

+ (CLXPlacementValidationResult *)validatePlacement:(NSString *)placementName
                                         placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements
                                    expectedAdType:(SDKConfigAdType)expectedAdType {
    CLXSDKConfigPlacement *foundPlacement = placements[placementName];
    
    // Check if placement exists
    if (!foundPlacement) {
        CLXError *error = [self createPlacementNotFoundError:placementName
                                                  placements:placements];
        return [CLXPlacementValidationResult failureWithError:error];
    }
    
    // Check if placement has correct ad type
    if (foundPlacement.type != expectedAdType) {
        CLXError *error = [self createWrongAdTypeError:placementName
                                       foundPlacement:foundPlacement
                                       expectedAdType:expectedAdType];
        return [CLXPlacementValidationResult failureWithError:error];
    }
    
    return [CLXPlacementValidationResult successWithPlacement:foundPlacement];
}

+ (CLXError *)createPlacementNotFoundError:(NSString *)placementName
                                placements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements {
    NSString *availablePlacementsString = [self formatAvailablePlacements:placements];
    
    NSString *description = [NSString stringWithFormat:
                             @"Placement '%@' not found in SDK configuration. Available placements: [%@].",
                             placementName,
                             availablePlacementsString];
    
    return [CLXError errorWithCode:CLXErrorCodeInvalidAdUnit
                       description:description];
}

+ (CLXError *)createWrongAdTypeError:(NSString *)placementName
                      foundPlacement:(CLXSDKConfigPlacement *)foundPlacement
                      expectedAdType:(SDKConfigAdType)expectedAdType {
    NSString *expectedTypeString = [self stringForAdType:expectedAdType];
    NSString *actualTypeString = [self stringForAdType:foundPlacement.type];
    
    NSString *description = [NSString stringWithFormat:
                             @"Placement '%@' exists but has wrong ad type. Requested: %@, Actual: %@.",
                             placementName,
                             expectedTypeString,
                             actualTypeString];
    
    return [CLXError errorWithCode:CLXErrorCodeInvalidAdUnit
                       description:description];
}

+ (NSString *)formatAvailablePlacements:(NSDictionary<NSString *, CLXSDKConfigPlacement *> *)placements {
    if (!placements || placements.count == 0) {
        return @"none";
    }
    
    NSArray<NSString *> *sortedNames = [[placements allKeys] sortedArrayUsingSelector:@selector(compare:)];
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
