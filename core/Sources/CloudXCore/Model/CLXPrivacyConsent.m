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
                        purpose3:(nullable NSNumber *)purpose3
                        purpose4:(nullable NSNumber *)purpose4
                   vendorConsent:(nullable NSNumber *)vendorConsent {
    self = [super init];
    if (self) {
        _purpose1 = purpose1;
        _purpose2 = purpose2;
        _purpose3 = purpose3;
        _purpose4 = purpose4;
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
    
    // GDPR/TCF: Personal data must be cleared if any purpose is explicitly denied (value = NO)
    // Note: nil values are treated as consent granted (lenient interpretation per IAB guidance)
    if (self.purpose1 && ![self.purpose1 boolValue]) return YES;
    if (self.purpose2 && ![self.purpose2 boolValue]) return YES;
    if (self.purpose3 && ![self.purpose3 boolValue]) return YES;
    if (self.purpose4 && ![self.purpose4 boolValue]) return YES;
    
    // GDPR/TCF: Personal data must be cleared if vendor consent is explicitly denied
    if (self.vendorConsent && ![self.vendorConsent boolValue]) return YES;
    
    return NO;
}

- (NSString *)description {
    // Determine if this is a CCPA consent or TCF consent based on which fields are set
    if (self.purpose1 || self.purpose2 || self.purpose3 || self.purpose4 || self.vendorConsent) {
        return [NSString stringWithFormat:@"<CLXPrivacyConsent(TCF): p1=%@, p2=%@, p3=%@, p4=%@, vendor=%@, requiresPiiRemoval=%@>",
                self.purpose1 ?: @"nil",
                self.purpose2 ?: @"nil",
                self.purpose3 ?: @"nil",
                self.purpose4 ?: @"nil",
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
    
    // Compare TCF fields
    BOOL tcfEqual = (self.purpose1 == other.purpose1 || [self.purpose1 isEqual:other.purpose1]) &&
                    (self.purpose2 == other.purpose2 || [self.purpose2 isEqual:other.purpose2]) &&
                    (self.purpose3 == other.purpose3 || [self.purpose3 isEqual:other.purpose3]) &&
                    (self.purpose4 == other.purpose4 || [self.purpose4 isEqual:other.purpose4]) &&
                    (self.vendorConsent == other.vendorConsent || [self.vendorConsent isEqual:other.vendorConsent]);
    
    return ccpaEqual && tcfEqual;
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    hash ^= [self.saleOptOut hash];
    hash ^= [self.sharingOptOut hash];
    hash ^= [self.purpose1 hash];
    hash ^= [self.purpose2 hash];
    hash ^= [self.purpose3 hash];
    hash ^= [self.purpose4 hash];
    hash ^= [self.vendorConsent hash];
    return hash;
}

@end
