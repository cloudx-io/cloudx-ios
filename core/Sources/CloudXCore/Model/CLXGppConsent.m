/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXGppConsent.m
 * @brief Implementation of GPP consent model
 * @details Provides business logic for determining personal data handling based on GPP consent flags
 */

#import <CloudXCore/CLXGppConsent.h>

@implementation CLXGppConsent

- (instancetype)initWithSaleOptOut:(nullable NSNumber *)saleOptOut 
                      sharingOptOut:(nullable NSNumber *)sharingOptOut {
    self = [super init];
    if (self) {
        _saleOptOut = saleOptOut;
        _sharingOptOut = sharingOptOut;
    }
    return self;
}

- (instancetype)init {
    return [self initWithSaleOptOut:nil sharingOptOut:nil];
}

- (BOOL)requiresPiiRemoval {
    // Personal data must be cleared if either sale or sharing opt-out is active (value = 1)
    BOOL saleOptOutActive = (self.saleOptOut && [self.saleOptOut integerValue] == 1);
    BOOL sharingOptOutActive = (self.sharingOptOut && [self.sharingOptOut integerValue] == 1);
    
    return saleOptOutActive || sharingOptOutActive;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<CLXGppConsent: saleOptOut=%@, sharingOptOut=%@, requiresPiiRemoval=%@>",
            self.saleOptOut ?: @"nil",
            self.sharingOptOut ?: @"nil", 
            @([self requiresPiiRemoval])];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[CLXGppConsent class]]) return NO;
    
    CLXGppConsent *other = (CLXGppConsent *)object;
    return [self.saleOptOut isEqual:other.saleOptOut] && 
           [self.sharingOptOut isEqual:other.sharingOptOut];
}

- (NSUInteger)hash {
    return [self.saleOptOut hash] ^ [self.sharingOptOut hash];
}

@end
