/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPrivacyConsent.h
 * @brief GPP consent model for privacy compliance
 * @details Represents parsed GPP consent data with business logic for personal data handling
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief GPP target sections for decoding
 * @discussion Defines the specific GPP sections to decode based on user geography
 */
typedef NS_ENUM(NSInteger, CLXGppTarget) {
    CLXGppTargetEUTCF = 2,      // EU TCF v2 (SID=2) - GDPR
    CLXGppTargetUSNational = 7, // US National (SID=7)
    CLXGppTargetUSCA = 8        // US California (SID=8)
};

/**
 * @class CLXPrivacyConsent
 * @brief Represents parsed GPP consent information
 * @discussion Contains opt-out flags and business logic for determining when to clear personal data
 */
@interface CLXPrivacyConsent : NSObject

/**
 * @brief Sale opt-out flag from GPP consent
 * @discussion 0=N/A, 1=OptOut, 2=DidNotOptOut
 */
@property (nonatomic, strong, nullable) NSNumber *saleOptOut;

/**
 * @brief Sharing opt-out flag from GPP consent  
 * @discussion 0=N/A, 1=OptOut, 2=DidNotOptOut
 */
@property (nonatomic, strong, nullable) NSNumber *sharingOptOut;

#pragma mark - TCF (GDPR) Properties

/**
 * @brief TCF Purpose 1 consent (Store and/or access information on a device)
 * @discussion YES=consent granted, NO=consent denied, nil=not collected
 * @note Required for basic SDK operation - storing device identifiers
 */
@property (nonatomic, strong, nullable) NSNumber *purpose1;

/**
 * @brief TCF Purpose 2 consent (Select basic ads)
 * @discussion YES=consent granted, NO=consent denied, nil=not collected
 * @note Required for serving contextual (non-personalized) ads
 */
@property (nonatomic, strong, nullable) NSNumber *purpose2;

/**
 * @brief TCF Vendor consent for CloudX (Vendor ID 1510)
 * @discussion YES=vendor consent granted, NO=denied, nil=not collected
 * @note CloudX must have vendor consent to process any user data
 */
@property (nonatomic, strong, nullable) NSNumber *vendorConsent;

/**
 * @brief Determines if personal data should be removed based on consent flags
 * @return YES if any opt-out or denial is active
 * @discussion Core business logic for privacy compliance. Returns YES if:
 *             - CCPA: saleOptOut == 1 OR sharingOptOut == 1
 *             - CCPA: Data is truncated/malformed (saleOptOut == nil when all GDPR fields nil)
 *             - GDPR: Purpose 1 OR Purpose 2 explicitly false OR vendorConsent explicitly false
 *             Note: nil values are treated as consent granted (lenient interpretation)
 */
- (BOOL)requiresPiiRemoval;

/**
 * @brief Initializes consent object with CCPA opt-out flags
 * @param saleOptOut Sale opt-out flag (0=N/A, 1=OptOut, 2=DidNotOptOut)
 * @param sharingOptOut Sharing opt-out flag (0=N/A, 1=OptOut, 2=DidNotOptOut)
 * @return Initialized consent object
 */
- (instancetype)initWithSaleOptOut:(nullable NSNumber *)saleOptOut 
                      sharingOptOut:(nullable NSNumber *)sharingOptOut;

/**
 * @brief Initializes consent object with TCF purpose and vendor consent
 * @param purpose1 Purpose 1 consent (store/access device info)
 * @param purpose2 Purpose 2 consent (select basic ads)
 * @param vendorConsent Vendor consent for CloudX (Vendor ID 1510)
 * @return Initialized consent object for GDPR/TCF
 * @note CloudX only requires purposes 1 and 2 per IAB GVL registration.
 */
- (instancetype)initWithPurpose1:(nullable NSNumber *)purpose1
                        purpose2:(nullable NSNumber *)purpose2
                   vendorConsent:(nullable NSNumber *)vendorConsent;

@end

NS_ASSUME_NONNULL_END
