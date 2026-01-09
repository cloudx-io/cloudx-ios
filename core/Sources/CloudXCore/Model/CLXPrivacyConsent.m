/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXPrivacyConsent.m
 * @brief Implementation of GPP consent model
 * @details Provides business logic for determining personal data handling based on GPP consent flags
 */

#import <CloudXCore/CLXPrivacyConsent.h>

@implementation CLXPrivacyConsent

- (instancetype)initWithSaleOptOut:(nullable NSNumber *)saleOptOut 
                      sharingOptOut:(nullable NSNumber *)sharingOptOut {
    self = [super init];
    if (self) {
        _saleOptOut = saleOptOut;
        _sharingOptOut = sharingOptOut;
    }
    return self;
}

- (instancetype)initWithPurpose1:(nullable NSNumber *)purpose1
                        purpose2:(nullable NSNumber *)purpose2
                   vendorConsent:(nullable NSNumber *)vendorConsent {
    self = [super init];
    if (self) {
        _purpose1 = purpose1;
        _purpose2 = purpose2;
        _vendorConsent = vendorConsent;
    }
    return self;
}

- (instancetype)init {
    return [self initWithSaleOptOut:nil sharingOptOut:nil];
}

- (BOOL)requiresPiiRemoval {
    // CCPA: Personal data must be cleared if either sale or sharing opt-out is active (value = 1)
    BOOL saleOptOutActive = (self.saleOptOut && [self.saleOptOut integerValue] == 1);
    BOOL sharingOptOutActive = (self.sharingOptOut && [self.sharingOptOut integerValue] == 1);
    
    if (saleOptOutActive || sharingOptOutActive) {
        return YES;
    }
    
    // GDPR/TCF: Personal data must be cleared if purpose 1 or 2 is explicitly denied (value = NO)
    // Note: nil values are treated as consent granted (lenient interpretation per IAB guidance)
    // CloudX only requires purposes 1 and 2 per IAB GVL registration.
    if (self.purpose1 && ![self.purpose1 boolValue]) return YES;
    if (self.purpose2 && ![self.purpose2 boolValue]) return YES;
    
    // GDPR/TCF: Personal data must be cleared if vendor consent is explicitly denied
    if (self.vendorConsent && ![self.vendorConsent boolValue]) return YES;
    
    // CCPA strict: If all GDPR fields are nil (indicating CCPA consent, not TCF),
    // and saleOptOut is nil but sharingOptOut has a value, this means truncated/malformed data
    // If BOTH are nil, it means "no CCPA data at all" which is fine (not opted out)
    BOOL isCcpaConsent = (self.purpose1 == nil && self.purpose2 == nil && self.vendorConsent == nil);
    if (isCcpaConsent && self.saleOptOut == nil && self.sharingOptOut != nil) {
        // Has sharingOptOut but no saleOptOut - malformed, be defensive
        return YES;
    }
    
    return NO;
}

- (NSString *)description {
    // Determine if this is a CCPA consent or TCF consent based on which fields are set
    if (self.purpose1 || self.purpose2 || self.vendorConsent) {
        return [NSString stringWithFormat:@"<CLXPrivacyConsent(TCF): p1=%@, p2=%@, vendor=%@, requiresPiiRemoval=%@>",
                self.purpose1 ?: @"nil",
                self.purpose2 ?: @"nil",
                self.vendorConsent ?: @"nil",
                @([self requiresPiiRemoval])];
    }
    return [NSString stringWithFormat:@"<CLXPrivacyConsent(CCPA): saleOptOut=%@, sharingOptOut=%@, requiresPiiRemoval=%@>",
            self.saleOptOut ?: @"nil",
            self.sharingOptOut ?: @"nil", 
            @([self requiresPiiRemoval])];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[CLXPrivacyConsent class]]) return NO;
    
    CLXPrivacyConsent *other = (CLXPrivacyConsent *)object;
    
    // Compare CCPA fields
    BOOL ccpaEqual = (self.saleOptOut == other.saleOptOut || [self.saleOptOut isEqual:other.saleOptOut]) &&
                     (self.sharingOptOut == other.sharingOptOut || [self.sharingOptOut isEqual:other.sharingOptOut]);
    
    // Compare TCF fields (only purposes 1-2)
    BOOL tcfEqual = (self.purpose1 == other.purpose1 || [self.purpose1 isEqual:other.purpose1]) &&
                    (self.purpose2 == other.purpose2 || [self.purpose2 isEqual:other.purpose2]) &&
                    (self.vendorConsent == other.vendorConsent || [self.vendorConsent isEqual:other.vendorConsent]);
    
    return ccpaEqual && tcfEqual;
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    hash ^= [self.saleOptOut hash];
    hash ^= [self.sharingOptOut hash];
    hash ^= [self.purpose1 hash];
    hash ^= [self.purpose2 hash];
    hash ^= [self.vendorConsent hash];
    return hash;
}

@end
