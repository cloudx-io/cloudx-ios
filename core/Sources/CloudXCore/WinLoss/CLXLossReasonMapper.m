/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXLossReasonMapper.m
 * @brief Implementation of CLXLossReasonMapper
 */

#import <CloudXCore/CLXLossReasonMapper.h>

@implementation CLXLossReasonMapper

+ (CLXLossReason)lossReasonFromError:(nullable NSError *)error {
    if (!error) {
        return CLXLossReasonInternalError;
    }
    
    // Check if it's a CloudX error domain
    if ([error.domain isEqualToString:CLXErrorDomain]) {
        return [self lossReasonFromErrorCode:(CLXErrorCode)error.code];
    }
    
    // For non-CloudX errors, try to infer from common patterns
    // NSURLErrorDomain timeout errors
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        if (error.code == NSURLErrorTimedOut) {
            return CLXLossReasonTimeout;
        }
        if (error.code == NSURLErrorNetworkConnectionLost ||
            error.code == NSURLErrorNotConnectedToInternet) {
            return CLXLossReasonInternalError;
        }
    }
    
    return CLXLossReasonInternalError;
}

+ (CLXLossReason)lossReasonFromErrorCode:(CLXErrorCode)errorCode {
    switch (errorCode) {
        // Timeout-related errors -> CLXLossReasonTimeout
        case CLXErrorCodeLoadTimeout:
        case CLXErrorCodeNetworkTimeout:
        case CLXErrorCodeAdapterTimeout:
            return CLXLossReasonTimeout;
            
        // No-fill errors -> CLXLossReasonNoFill
        case CLXErrorCodeNoFill:
        case CLXErrorCodeAdapterNoFill:
            return CLXLossReasonNoFill;
            
        // Invalid bid/ad errors -> CLXLossReasonInvalidBid
        case CLXErrorCodeInvalidBidResponse:
        case CLXErrorCodeInvalidAd:
        case CLXErrorCodeInvalidResponse:
            return CLXLossReasonInvalidBid;
            
        // Expired ad -> CLXLossReasonExpired
        case CLXErrorCodeAdExpired:
            return CLXLossReasonExpired;
            
        // Rate limiting -> CLXLossReasonRateLimited
        case CLXErrorCodeTooManyRequests:
            return CLXLossReasonRateLimited;
            
        // All other errors default to internal error
        default:
            return CLXLossReasonInternalError;
    }
}

@end
