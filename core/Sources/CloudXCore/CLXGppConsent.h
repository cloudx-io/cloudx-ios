/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXGppConsent.h
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
    CLXGppTargetUSCA = 8,       // US California (SID=8)
    CLXGppTargetUSNational = 7  // US National (SID=7)
};

/**
 * @class CLXGppConsent
 * @brief Represents parsed GPP consent information
 * @discussion Contains opt-out flags and business logic for determining when to clear personal data
 */
@interface CLXGppConsent : NSObject

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

/**
 * @brief Determines if personal data should be removed based on consent flags
 * @return YES if either sale or sharing opt-out is active (value = 1)
 * @discussion Core business logic for privacy compliance - any opt-out requires data clearing
 */
- (BOOL)requiresPiiRemoval;

/**
 * @brief Initializes consent object with opt-out flags
 * @param saleOptOut Sale opt-out flag (0=N/A, 1=OptOut, 2=DidNotOptOut)
 * @param sharingOptOut Sharing opt-out flag (0=N/A, 1=OptOut, 2=DidNotOptOut)
 * @return Initialized consent object
 */
- (instancetype)initWithSaleOptOut:(nullable NSNumber *)saleOptOut 
                      sharingOptOut:(nullable NSNumber *)sharingOptOut;

@end

NS_ASSUME_NONNULL_END
