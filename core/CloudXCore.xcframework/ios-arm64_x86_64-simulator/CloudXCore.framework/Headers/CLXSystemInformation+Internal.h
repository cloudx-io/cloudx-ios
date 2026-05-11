/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXSystemInformation+Internal.h
 * @brief Internal helpers and wire-format constants for system information.
 * @discussion These symbols are referenced only by CloudXCore's own system
 *             information implementation and its test suite. They are
 *             intentionally hidden in the shipped binary.
 *
 *             The `CLXAppDistribution*` constants name the canonical wire
 *             values for the `appDistribution` field sent to the SSP. Tests
 *             compare against the same symbols to catch typos at compile time.
 *
 *             `CLXClassifyAppDistributionFromReceiptPath` is the pure receipt
 *             classification function used internally by
 *             `CLXSystemInformation.appDistribution`; unit tests call it
 *             directly with fixture paths.
 *
 *             `DeviceTypeToString` is a small helper used by telemetry payload
 *             construction.
 */

#import <CloudXCore/CLXSystemInformation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const CLXAppDistributionSimulator;
FOUNDATION_EXPORT NSString * const CLXAppDistributionDebug;
FOUNDATION_EXPORT NSString * const CLXAppDistributionTestFlight;
FOUNDATION_EXPORT NSString * const CLXAppDistributionEnterprise;
FOUNDATION_EXPORT NSString * const CLXAppDistributionAppStore;

FOUNDATION_EXPORT NSString * _Nonnull DeviceTypeToString(DeviceType type);

/**
 * Classifies an app distribution channel from the receipt path and embedded-provisioning
 * state. Exposed for unit testing; production callers should use `CLXSystemInformation.shared.appDistribution`.
 *
 * @param receiptPath             Path from `[[NSBundle mainBundle] appStoreReceiptURL].path`,
 *                                or a test fixture. May be nil.
 * @param embeddedProvisionPresent YES if `embedded.mobileprovision` exists in the bundle.
 * @return `CLXAppDistributionTestFlight` / `CLXAppDistributionEnterprise` /
 *         `CLXAppDistributionAppStore`, or nil when the classifier cannot match.
 *         Does not handle simulator or debug slices — those are compile-time branches
 *         in the caller.
 */
FOUNDATION_EXPORT NSString * _Nullable CLXClassifyAppDistributionFromReceiptPath(NSString * _Nullable receiptPath,
                                                                                 BOOL embeddedProvisionPresent);

NS_ASSUME_NONNULL_END
