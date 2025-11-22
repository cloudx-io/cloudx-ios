/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXAdapterErrorMapper.h"

@implementation CLXAdapterErrorMapper

+ (NSError *)errorForValidationFailure:(CLXAdapterValidationError)validationError
                               context:(NSString *)context
                           placementID:(nullable NSString *)placementID
                               network:(NSString *)network {
    CLXErrorCode errorCode;
    NSString *description;
    
    switch (validationError) {
        case CLXAdapterValidationErrorInvalidPlacementID:
            errorCode = CLXErrorCodeInvalidAdUnitID;
            if (placementID && placementID.length > 0) {
                description = [NSString stringWithFormat:@"[%@] Invalid placement ID '%@' for %@ ad", 
                             network, placementID, context];
            } else {
                description = [NSString stringWithFormat:@"[%@] Missing or empty placement ID for %@ ad", 
                             network, context];
            }
            break;
            
        case CLXAdapterValidationErrorInvalidBidPayload:
            errorCode = CLXErrorCodeInvalidBidResponse;
            description = [NSString stringWithFormat:@"[%@] Invalid bid payload for %@ ad", 
                         network, context];
            break;
            
        case CLXAdapterValidationErrorSDKNotInitialized:
            errorCode = CLXErrorCodeNotInitialized;
            description = [NSString stringWithFormat:
                         @"[%@] %@ SDK not initialized. Verify adapter configuration includes valid initialization parameters.", 
                         network, network];
            break;
            
        case CLXAdapterValidationErrorUnsupportedAdFormat:
            errorCode = CLXErrorCodeUnsupportedAdFormat;
            description = [NSString stringWithFormat:@"[%@] Unsupported %@ ad format", 
                         network, context];
            break;
            
        case CLXAdapterValidationErrorMissingDelegate:
            errorCode = CLXErrorCodeInvalidConfiguration;
            description = [NSString stringWithFormat:@"[%@] Missing delegate for %@ ad", 
                         network, context];
            break;
            
        case CLXAdapterValidationErrorMissingViewController:
            errorCode = CLXErrorCodeInvalidConfiguration;
            description = [NSString stringWithFormat:@"[%@] Missing view controller for %@ ad", 
                         network, context];
            break;
            
        case CLXAdapterValidationErrorMissingBidID:
            errorCode = CLXErrorCodeInvalidBidResponse;
            description = [NSString stringWithFormat:@"[%@] Missing bid ID for %@ ad", 
                         network, context];
            break;
            
        default:
            errorCode = CLXErrorCodeUnknown;
            description = [NSString stringWithFormat:@"[%@] Unknown validation error for %@ ad", 
                         network, context];
            break;
    }
    
    NSMutableDictionary *userInfo = [@{
        NSLocalizedDescriptionKey: description,
        @"network": network,
        @"context": context,
        @"validationError": @(validationError)
    } mutableCopy];
    
    if (placementID) {
        userInfo[@"placementID"] = placementID;
    }
    
    return [CLXError errorWithCode:errorCode description:description];
}

+ (NSError *)invalidPlacementIDErrorForNetwork:(NSString *)network
                                       context:(NSString *)context
                                   placementID:(nullable NSString *)placementID {
    return [self errorForValidationFailure:CLXAdapterValidationErrorInvalidPlacementID
                                   context:context
                               placementID:placementID
                                   network:network];
}

+ (NSError *)sdkNotInitializedErrorForNetwork:(NSString *)network
                                      context:(NSString *)context {
    return [self errorForValidationFailure:CLXAdapterValidationErrorSDKNotInitialized
                                   context:context
                               placementID:nil
                                   network:network];
}

+ (NSError *)unsupportedFormatErrorForNetwork:(NSString *)network
                                      context:(NSString *)context
                                   formatInfo:(nullable NSString *)formatInfo {
    NSError *error = [self errorForValidationFailure:CLXAdapterValidationErrorUnsupportedAdFormat
                                              context:context
                                          placementID:nil
                                              network:network];
    
    if (formatInfo) {
        NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
        userInfo[@"formatInfo"] = formatInfo;
        return [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    }
    
    return error;
}

@end

