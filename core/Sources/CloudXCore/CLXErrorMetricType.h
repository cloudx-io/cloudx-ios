/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXErrorMetricType.h
 * @brief Error metric type definitions for telemetry tracking
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Error metric types for tracking different categories of SDK errors
 * These are sent via the metrics system for observability
 */
typedef NS_ENUM(NSInteger, CLXErrorMetricType) {
    /// JSON serialization/deserialization errors
    CLXErrorMetricTypeJSONParsing = 1,
    /// Network timeout and connectivity errors
    CLXErrorMetricTypeNetworkTimeout = 2,
    /// UserDefaults access and storage errors
    CLXErrorMetricTypeUserDefaultsAccess = 3,
    /// Invalid configuration data errors
    CLXErrorMetricTypeConfigurationInvalid = 4,
    /// Adapter initialization and setup errors
    CLXErrorMetricTypeAdapterInitialization = 5,
    /// Base64 encoding/decoding errors
    CLXErrorMetricTypeBase64Processing = 6,
    /// String manipulation and processing errors
    CLXErrorMetricTypeStringProcessing = 7,
    /// URL construction and validation errors
    CLXErrorMetricTypeURLConstruction = 8
};

/**
 * Converts error metric type to string representation for server reporting
 * @param type The error metric type
 * @return String representation of the error type
 */
NSString *CLXErrorMetricTypeString(CLXErrorMetricType type);

/**
 * Classifies an NSException into an appropriate error metric type
 * @param exception The exception to classify
 * @return The most appropriate error metric type for the exception
 */
CLXErrorMetricType CLXErrorMetricTypeFromException(NSException *exception);

/**
 * Classifies an NSError into an appropriate error metric type
 * @param error The error to classify
 * @return The most appropriate error metric type for the error
 */
CLXErrorMetricType CLXErrorMetricTypeFromError(NSError *error);

NS_ASSUME_NONNULL_END
