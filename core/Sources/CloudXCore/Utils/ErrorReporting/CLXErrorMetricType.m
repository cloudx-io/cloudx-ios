/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXErrorMetricType.m
 * @brief Implementation of error metric type utilities
 */

#import <CloudXCore/CLXErrorMetricType.h>

NSString *CLXErrorMetricTypeString(CLXErrorMetricType type) {
    switch (type) {
        case CLXErrorMetricTypeJSONParsing:
            return @"error_json_parsing";
        case CLXErrorMetricTypeNetworkTimeout:
            return @"error_network_timeout";
        case CLXErrorMetricTypeUserDefaultsAccess:
            return @"error_userdefaults_access";
        case CLXErrorMetricTypeConfigurationInvalid:
            return @"error_configuration_invalid";
        case CLXErrorMetricTypeAdapterInitialization:
            return @"error_adapter_initialization";
        case CLXErrorMetricTypeBase64Processing:
            return @"error_base64_processing";
        case CLXErrorMetricTypeStringProcessing:
            return @"error_string_processing";
        case CLXErrorMetricTypeURLConstruction:
            return @"error_url_construction";
        default:
            return @"error_unknown";
    }
}

CLXErrorMetricType CLXErrorMetricTypeFromException(NSException *exception) {
    if (!exception || !exception.name) {
        return CLXErrorMetricTypeStringProcessing;
    }
    
    NSString *exceptionName = exception.name;
    NSString *reason = exception.reason ?: @"";
    
    // JSON-related exceptions
    if ([exceptionName isEqualToString:NSInvalidArgumentException] && 
        ([reason containsString:@"JSON"] || [reason containsString:@"serialization"])) {
        return CLXErrorMetricTypeJSONParsing;
    }
    
    // Base64-related exceptions
    if ([reason containsString:@"base64"] || [reason containsString:@"Base64"]) {
        return CLXErrorMetricTypeBase64Processing;
    }
    
    // URL-related exceptions
    if ([reason containsString:@"URL"] || [reason containsString:@"url"]) {
        return CLXErrorMetricTypeURLConstruction;
    }
    
    // UserDefaults-related exceptions
    if ([reason containsString:@"UserDefaults"] || [reason containsString:@"defaults"]) {
        return CLXErrorMetricTypeUserDefaultsAccess;
    }
    
    // Configuration-related exceptions
    if ([reason containsString:@"config"] || [reason containsString:@"Config"]) {
        return CLXErrorMetricTypeConfigurationInvalid;
    }
    
    // Adapter-related exceptions
    if ([reason containsString:@"adapter"] || [reason containsString:@"Adapter"]) {
        return CLXErrorMetricTypeAdapterInitialization;
    }
    
    // Default to string processing for unclassified exceptions
    return CLXErrorMetricTypeStringProcessing;
}

CLXErrorMetricType CLXErrorMetricTypeFromError(NSError *error) {
    if (!error) {
        return CLXErrorMetricTypeStringProcessing;
    }
    
    NSString *domain = error.domain ?: @"";
    NSString *description = error.localizedDescription ?: @"";
    
    // Network-related errors
    if ([domain isEqualToString:NSURLErrorDomain]) {
        if (error.code == NSURLErrorTimedOut || 
            error.code == NSURLErrorNetworkConnectionLost ||
            error.code == NSURLErrorNotConnectedToInternet) {
            return CLXErrorMetricTypeNetworkTimeout;
        }
    }
    
    // JSON-related errors
    if ([domain isEqualToString:NSCocoaErrorDomain] && 
        ([description containsString:@"JSON"] || [description containsString:@"serialization"])) {
        return CLXErrorMetricTypeJSONParsing;
    }
    
    // Configuration-related errors
    if ([description containsString:@"config"] || [description containsString:@"Config"]) {
        return CLXErrorMetricTypeConfigurationInvalid;
    }
    
    // Default classification
    return CLXErrorMetricTypeStringProcessing;
}
