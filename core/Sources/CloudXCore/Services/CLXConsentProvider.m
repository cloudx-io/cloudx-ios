/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXConsentProvider.m
 * @brief Implementation of GPP provider service
 * @details Handles GPP string parsing with support for US-CA and US-National sections
 */

#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXErrorReporter.h>

// IAB GPP UserDefaults keys
NSString * const kIABGPP_GppString = @"IABGPP_HDR_GppString";
NSString * const kIABGPP_GppSID = @"IABGPP_GppSID";

// IAB TCF UserDefaults keys
static NSString * const kIABTCF_TCString = @"IABTCF_TCString";
static NSString * const kIABTCF_gdprApplies = @"IABTCF_gdprApplies";

// GPP constants for legacy TCF fallback
NSString * const kGPPHeaderTcfEuOnly = @"DBABMA";
NSInteger const kGPPSidEuTcf = 2;

// CloudX vendor ID in IAB Global Vendor List
static NSInteger const kCloudXVendorId = 1510;

// TCF v2 Core String bit offsets (per IAB spec)
// https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20Consent%20string%20and%20vendor%20list%20formats%20v2.md
static NSUInteger const kTCFPurposeConsentOffset = 152;     // Purposes 1-24 (24 bits)
static NSUInteger const kTCFMaxVendorIdOffset = 213;        // MaxVendorId (16 bits)
static NSUInteger const kTCFMaxVendorIdLength = 16;
static NSUInteger const kTCFEncodingTypeOffset = 229;       // EncodingType (1 bit: 0=BitField, 1=Range)
static NSUInteger const kTCFVendorConsentOffset = 230;      // Vendor consent section starts here

@interface CLXConsentProvider ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong, nullable) CLXErrorReporter *errorReporter;
@end

@interface CLXConsentProvider (ErrorReporting)
- (void)reportException:(NSException *)exception context:(NSDictionary<NSString *, NSString *> *)context;
@end

@implementation CLXConsentProvider

+ (instancetype)sharedInstance {
    static CLXConsentProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithErrorReporter:[CLXErrorReporter shared]];
    });
    return sharedInstance;
}

- (instancetype)init {
    return [self initWithErrorReporter:nil];
}

- (instancetype)initWithErrorReporter:(nullable CLXErrorReporter *)errorReporter {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXConsentProvider"];
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _errorReporter = errorReporter;
    }
    return self;
}

- (nullable NSString *)gppString {
    @try {
        NSString *gppString = [self.userDefaults stringForKey:kIABGPP_GppString];
        if (gppString.length > 0) {
            [self.logger verbose:[NSString stringWithFormat:@"GPP string: %@", gppString]];
            return gppString;
        }
        [self.logger verbose:@"GPP string: (none)"];
        return nil;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to read GPP string: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSArray<NSNumber *> *)gppSid {
    @try {
        NSString *rawSid = [self.userDefaults stringForKey:kIABGPP_GppSID];
        if (rawSid.length == 0) {
            [self.logger verbose:@"GPP SID: (none)"];
            return nil;
        }
        
        // Parse SID with flexible delimiters (_ and ,) - matching Android implementation
        NSString *trimmedSid = [rawSid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSArray<NSString *> *sidComponents = [trimmedSid componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"_,"]];
        
        NSMutableArray<NSNumber *> *parsedSids = [NSMutableArray array];
        for (NSString *component in sidComponents) {
            NSString *trimmedComponent = [component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (trimmedComponent.length > 0) {
                NSInteger sidValue = [trimmedComponent integerValue];
                if (sidValue > 0) {
                    [parsedSids addObject:@(sidValue)];
                }
            }
        }
        
        if (parsedSids.count > 0) {
            // Remove duplicates and sort - matching Android behavior
            NSOrderedSet *uniqueSids = [NSOrderedSet orderedSetWithArray:parsedSids];
            NSArray<NSNumber *> *sortedSids = [[uniqueSids array] sortedArrayUsingSelector:@selector(compare:)];
            [self.logger verbose:[NSString stringWithFormat:@"GPP SID: %@", sortedSids]];
            return sortedSids;
        }
        
        [self.logger verbose:@"GPP SID: (none - no valid values)"];
        return nil;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to parse GPP SID: %@", exception.reason]];
        return nil;
    }
}

- (nullable CLXPrivacyConsent *)decodeGppForTarget:(nullable NSNumber *)target {
    NSString *gpp = [self gppString];
    NSArray<NSNumber *> *sids = [self gppSid];
    
    if (!gpp || !sids || sids.count == 0) {
        [self.logger debug:@"No GPP data available for decoding"];
        return nil;
    }
    
    if (target) {
        // Decode specific target
        CLXPrivacyConsent *consent = [self decodeGppSection:gpp sids:sids targetSid:[target integerValue]];
        if (consent && [consent requiresPiiRemoval]) {
            [self.logger debug:[NSString stringWithFormat:@"Decoded target %@ with PII removal required", target]];
            return consent;
        }
        [self.logger debug:[NSString stringWithFormat:@"Target %@ does not require PII removal", target]];
        return nil;
    } else {
        // Auto-select: prioritize consent requiring PII removal, then first available
        NSArray<NSNumber *> *prioritySids = @[@(CLXGppTargetUSCA), @(CLXGppTargetUSNational)];
        NSMutableArray<CLXPrivacyConsent *> *decodedConsents = [NSMutableArray array];
        
        for (NSNumber *sidNumber in prioritySids) {
            CLXPrivacyConsent *consent = [self decodeGppSection:gpp sids:sids targetSid:[sidNumber integerValue]];
            if (consent) {
                [decodedConsents addObject:consent];
            }
        }
        
        // Find first consent requiring PII removal
        for (CLXPrivacyConsent *consent in decodedConsents) {
            if ([consent requiresPiiRemoval]) {
                [self.logger debug:@"Auto-selected consent requiring PII removal"];
                return consent;
            }
        }
        
        // Return first available if none require PII removal
        if (decodedConsents.count > 0) {
            [self.logger debug:@"Auto-selected first available consent"];
            return decodedConsents.firstObject;
        }
        
        [self.logger debug:@"No decodable consent found"];
        return nil;
    }
}

- (nullable CLXPrivacyConsent *)decodeGppSection:(NSString *)gpp sids:(NSArray<NSNumber *> *)sids targetSid:(NSInteger)targetSid {
    if (![sids containsObject:@(targetSid)]) {
        [self.logger debug:[NSString stringWithFormat:@"SID %ld not present in GPP", (long)targetSid]];
        return nil;
    }
    
    @try {
        NSString *payload = [self selectSectionPayload:gpp sids:sids targetSid:targetSid];
        if (!payload) {
            [self.logger error:[NSString stringWithFormat:@"Failed to extract payload for SID %ld", (long)targetSid]];
            return nil;
        }
        
        if (targetSid == CLXGppTargetUSCA) {
            return [self decodeUsCa:payload];
        } else if (targetSid == CLXGppTargetUSNational) {
            return [self decodeUsNational:payload];
        } else if (targetSid == CLXGppTargetEUTCF) {
            return [self decodeEuTcf:payload];
        } else {
            [self.logger error:[NSString stringWithFormat:@"Unsupported SID %ld", (long)targetSid]];
            return nil;
        }
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to decode SID %ld: %@", (long)targetSid, exception.reason]];
        return nil;
    }
}

- (nullable NSString *)selectSectionPayload:(NSString *)gpp sids:(NSArray<NSNumber *> *)sids targetSid:(NSInteger)targetSid {
    NSArray<NSString *> *parts = [gpp componentsSeparatedByString:@"~"];
    NSMutableArray<NSString *> *payloads = [NSMutableArray array];
    
    // Skip header (first part) and collect payloads
    for (NSUInteger i = 1; i < parts.count; i++) {
        NSString *part = parts[i];
        if (part.length > 0) {
            [payloads addObject:part];
        }
    }
    
    if (payloads.count == 0) {
        [self.logger error:@"GPP string has no payload sections"];
        return nil;
    }
    
    // Find index of target SID in sorted SID array
    NSUInteger sidIndex = [sids indexOfObject:@(targetSid)];
    if (sidIndex == NSNotFound || sidIndex >= payloads.count) {
        [self.logger error:[NSString stringWithFormat:@"SID %ld index %lu out of range for %lu payloads", (long)targetSid, (unsigned long)sidIndex, (unsigned long)payloads.count]];
        return nil;
    }
    
    NSString *payload = payloads[sidIndex];
    // Remove any trailing parameters (everything after first '.')
    NSRange dotRange = [payload rangeOfString:@"."];
    if (dotRange.location != NSNotFound) {
        payload = [payload substringToIndex:dotRange.location];
    }
    
    return payload;
}

- (nullable CLXPrivacyConsent *)decodeUsCa:(NSString *)payload {
    @try {
        NSString *bits = [self base64UrlToBits:payload];
        if (!bits) {
            [self.logger error:@"Failed to decode US-CA payload to bits"];
            return nil;
        }
        
        // US-CA section: saleOptOut at bit 12 (2 bits), sharingOptOut at bit 14 (2 bits)
        NSNumber *saleOptOut = [self readBits:bits start:12 length:2];
        NSNumber *sharingOptOut = [self readBits:bits start:14 length:2];
        
        CLXPrivacyConsent *consent = [[CLXPrivacyConsent alloc] initWithSaleOptOut:saleOptOut sharingOptOut:sharingOptOut];
        [self.logger debug:[NSString stringWithFormat:@"US-CA decoded: %@", consent]];
        return consent;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"US-CA decode failed: %@", exception.reason]];
        return nil;
    }
}

- (nullable CLXPrivacyConsent *)decodeUsNational:(NSString *)payload {
    @try {
        NSString *bits = [self base64UrlToBits:payload];
        if (!bits) {
            [self.logger error:@"Failed to decode US-National payload to bits"];
            return nil;
        }
        
        // US-National section: saleOptOut at bit 18 (2 bits), sharingOptOut at bit 20 (2 bits), targetedOptOut at bit 22 (2 bits)
        NSNumber *saleOptOut = [self readBits:bits start:18 length:2];
        NSNumber *sharingOptOut = [self readBits:bits start:20 length:2];
        NSNumber *targetedOptOut = [self readBits:bits start:22 length:2];
        
        // Use sharingOptOut if available, otherwise fall back to targetedOptOut (matching Android logic)
        NSNumber *effectiveSharingOptOut = sharingOptOut ?: targetedOptOut;
        
        // Default saleOptOut to 0 when unknown/N/A (matching Android logic)
        NSNumber *effectiveSaleOptOut = saleOptOut ?: @0;
        
        CLXPrivacyConsent *consent = [[CLXPrivacyConsent alloc] initWithSaleOptOut:effectiveSaleOptOut sharingOptOut:effectiveSharingOptOut];
        [self.logger debug:[NSString stringWithFormat:@"US-National decoded: %@", consent]];
        return consent;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"US-National decode failed: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSData *)decodeBase64Url:(NSString *)encoded {
    // Manual URL-safe base64 decoder that handles Android's lenient Base64.URL_SAFE behavior
    // Accepts incomplete padding (even ===) which iOS's standard decoder rejects
    
    static const char base64UrlTable[256] = {
        -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1,
        -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,-1,
        -1,-1,-1,-1, -1,-1,-1,-1, -1,-1,-1,62, -1,62,-1,63,
        52,53,54,55, 56,57,58,59, 60,61,-1,-1, -1,-1,-1,-1,
        -1, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
        15,16,17,18, 19,20,21,22, 23,24,25,-1, -1,-1,-1,63,
        -1,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
        41,42,43,44, 45,46,47,48, 49,50,51,-1, -1,-1,-1,-1
    };
    
    NSMutableData *result = [NSMutableData data];
    const char *input = [encoded UTF8String];
    NSUInteger length = encoded.length;
    
    unsigned int accumulator = 0;
    int bitsCollected = 0;
    
    for (NSUInteger i = 0; i < length; i++) {
        unsigned char c = input[i];
        if (c == '=') break; // Stop at padding
        
        int value = (c < 256) ? base64UrlTable[c] : -1;
        if (value == -1) continue; // Skip invalid characters
        
        accumulator = (accumulator << 6) | value;
        bitsCollected += 6;
        
        if (bitsCollected >= 8) {
            bitsCollected -= 8;
            unsigned char byte = (accumulator >> bitsCollected) & 0xFF;
            [result appendBytes:&byte length:1];
        }
    }
    
    return result.length > 0 ? result : nil;
}

- (nullable NSString *)base64UrlToBits:(NSString *)encoded {
    if (encoded.length == 0) return nil;
    
    @try {
        [self.logger debug:[NSString stringWithFormat:@"Decoding payload: '%@' (length: %lu)", encoded, (unsigned long)encoded.length]];
        
        // Use custom lenient decoder that matches Android's Base64.URL_SAFE behavior
        NSData *decodedData = [self decodeBase64Url:encoded];
        if (!decodedData) {
            [self.logger error:[NSString stringWithFormat:@"Base64URL decoding failed for: '%@'", encoded]];
            return nil;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"Decoded %lu bytes", (unsigned long)decodedData.length]];
        
        // Convert to bit string
        NSMutableString *bits = [NSMutableString string];
        const uint8_t *bytes = (const uint8_t *)decodedData.bytes;
        for (NSUInteger i = 0; i < decodedData.length; i++) {
            for (int bit = 7; bit >= 0; bit--) {
                [bits appendString:((bytes[i] >> bit) & 1) ? @"1" : @"0"];
            }
        }
        
        return [bits copy];
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Base64URL to bits conversion failed: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSNumber *)readBits:(NSString *)bits start:(NSUInteger)start length:(NSUInteger)length {
    if (start + length > bits.length) {
        [self.logger error:[NSString stringWithFormat:@"Bit range %lu-%lu exceeds string length %lu", 
                           (unsigned long)start, (unsigned long)(start + length), (unsigned long)bits.length]];
        return nil;
    }
    
    @try {
        NSString *bitSubstring = [bits substringWithRange:NSMakeRange(start, length)];
        NSInteger value = 0;
        
        for (NSUInteger i = 0; i < length; i++) {
            unichar bit = [bitSubstring characterAtIndex:i];
            if (bit == '1') {
                value |= (1 << (length - 1 - i));
            }
        }
        return @(value);
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Exception in bit_string_parsing: %@ - %@", 
                           exception.name ?: @"unknown", exception.reason ?: @"no reason"]];
        [self reportException:exception context:@{@"operation": @"bit_string_parsing", @"start": [@(start) stringValue], @"length": [@(length) stringValue]}];
        return nil;
    }
}

#pragma mark - TCF (GDPR) Methods

- (nullable NSString *)tcString {
    @try {
        NSString *tcString = [self.userDefaults stringForKey:kIABTCF_TCString];
        if (tcString.length > 0) {
            [self.logger verbose:[NSString stringWithFormat:@"TCF string: %@", tcString]];
            return tcString;
        }
        [self.logger verbose:@"TCF string: (none)"];
        return nil;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to read TCF string: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSNumber *)gdprApplies {
    @try {
        // IAB TCF spec requires integer: 0 = does not apply, 1 = applies
        if (![self.userDefaults objectForKey:kIABTCF_gdprApplies]) {
            [self.logger verbose:@"GDPR applies: (unknown)"];
            return nil;
        }
        
        NSInteger gdprValue = [self.userDefaults integerForKey:kIABTCF_gdprApplies];
        if (gdprValue == 0) {
            [self.logger verbose:@"GDPR applies: NO"];
            return @NO;
        } else if (gdprValue == 1) {
            [self.logger verbose:@"GDPR applies: YES"];
            return @YES;
        } else {
            [self.logger warn:[NSString stringWithFormat:@"GDPR applies has invalid value: %ld (expected 0 or 1)", (long)gdprValue]];
            return nil;
        }
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to read GDPR applies: %@", exception.reason]];
        return nil;
    }
}

- (nullable CLXPrivacyConsent *)decodeTcString:(NSString *)tcString {
    if (!tcString || tcString.length == 0) {
        [self.logger error:@"Cannot decode nil or empty TCF string"];
        return nil;
    }
    
    @try {
        NSString *bits = [self base64UrlToBits:tcString];
        if (!bits) {
            [self.logger error:@"Failed to decode TCF string to bits"];
            return nil;
        }
        
        [self.logger debug:[NSString stringWithFormat:@"Decoded TCF bit string length: %lu bits", (unsigned long)bits.length]];
        
        // Read purpose consents (purposes 1-4)
        NSNumber *purpose1 = [self readBitAsBool:bits index:kTCFPurposeConsentOffset];
        NSNumber *purpose2 = [self readBitAsBool:bits index:kTCFPurposeConsentOffset + 1];
        NSNumber *purpose3 = [self readBitAsBool:bits index:kTCFPurposeConsentOffset + 2];
        NSNumber *purpose4 = [self readBitAsBool:bits index:kTCFPurposeConsentOffset + 3];
        
        // Read vendor consent for CloudX
        NSNumber *vendorConsent = [self parseVendorConsent:bits vendorId:kCloudXVendorId];
        
        CLXPrivacyConsent *consent = [[CLXPrivacyConsent alloc] initWithPurpose1:purpose1
                                                                purpose2:purpose2
                                                                purpose3:purpose3
                                                                purpose4:purpose4
                                                           vendorConsent:vendorConsent];
        
        [self.logger debug:[NSString stringWithFormat:@"TCF decoded: %@", consent]];
        return consent;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"TCF string decode failed: %@", exception.reason]];
        [self reportException:exception context:@{@"operation": @"decodeTcString"}];
        return nil;
    }
}

- (nullable CLXPrivacyConsent *)decodeEuTcf:(NSString *)payload {
    @try {
        if (!payload || payload.length == 0) {
            [self.logger error:@"Failed to extract Section 2 payload from GPP string"];
            return nil;
        }
        
        return [self decodeTcString:payload];
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"EU-TCF decode failed: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSString *)extractTcStringFromGpp {
    NSString *gpp = [self gppString];
    NSArray<NSNumber *> *sids = [self gppSid];
    
    if (!gpp || !sids || sids.count == 0) {
        return nil;
    }
    
    if (![sids containsObject:@(kGPPSidEuTcf)]) {
        return nil;
    }
    
    return [self selectSectionPayload:gpp sids:sids targetSid:kGPPSidEuTcf];
}

#pragma mark - TCF Vendor Consent Parsing

- (nullable NSNumber *)readBitAsBool:(NSString *)bits index:(NSUInteger)index {
    if (index >= bits.length) {
        return @NO;
    }
    return @([bits characterAtIndex:index] == '1');
}

- (NSInteger)readInt:(NSString *)bits offset:(NSUInteger)offset length:(NSUInteger)length {
    if (offset + length > bits.length) {
        return 0;
    }
    
    NSString *substring = [bits substringWithRange:NSMakeRange(offset, length)];
    NSInteger value = 0;
    for (NSUInteger i = 0; i < length; i++) {
        if ([substring characterAtIndex:i] == '1') {
            value |= (1 << (length - 1 - i));
        }
    }
    return value;
}

/**
 * Parses vendor consent section from TCF v2 Core String.
 * The vendor consent section can be encoded as BitField or Range.
 */
- (nullable NSNumber *)parseVendorConsent:(NSString *)bits vendorId:(NSInteger)vendorId {
    @try {
        if (bits.length < kTCFVendorConsentOffset) {
            [self.logger error:[NSString stringWithFormat:@"TCF string too short (%lu bits), missing vendor consent section", (unsigned long)bits.length]];
            return @NO;
        }
        
        NSInteger maxVendorId = [self readInt:bits offset:kTCFMaxVendorIdOffset length:kTCFMaxVendorIdLength];
        
        if (maxVendorId < vendorId) {
            [self.logger debug:[NSString stringWithFormat:@"Vendor %ld is beyond MaxVendorId (%ld), no consent", (long)vendorId, (long)maxVendorId]];
            return @NO;
        }
        
        BOOL isRangeEncoding = [bits characterAtIndex:kTCFEncodingTypeOffset] == '1';
        
        if (isRangeEncoding) {
            return [self parseVendorConsentRange:bits vendorId:vendorId offset:kTCFVendorConsentOffset];
        } else {
            return [self parseVendorConsentBitField:bits vendorId:vendorId offset:kTCFVendorConsentOffset];
        }
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to parse vendor consent: %@", exception.reason]];
        return @NO;
    }
}

/**
 * Parses BitField encoding for vendor consent.
 * BitField format: MaxVendorId bits starting at offset, where bit i represents vendor ID i+1
 */
- (NSNumber *)parseVendorConsentBitField:(NSString *)bits vendorId:(NSInteger)vendorId offset:(NSUInteger)offset {
    // In BitField, vendor IDs start at 1, so vendor 1 is at bit 0, vendor N at bit N-1
    NSUInteger bitIndex = offset + (vendorId - 1);
    
    if (bitIndex >= bits.length) {
        [self.logger error:[NSString stringWithFormat:@"BitField too short for vendor %ld", (long)vendorId]];
        return @NO;
    }
    
    return @([bits characterAtIndex:bitIndex] == '1');
}

/**
 * Parses Range encoding for vendor consent.
 * Range format:
 * - NumEntries (12 bits): Number of range entries
 * - For each entry:
 *   - IsRange (1 bit): 0=single ID, 1=range
 *   - If IsRange=0: StartVendorId (16 bits)
 *   - If IsRange=1: StartVendorId (16 bits) + EndVendorId (16 bits)
 */
- (NSNumber *)parseVendorConsentRange:(NSString *)bits vendorId:(NSInteger)vendorId offset:(NSUInteger)offset {
    NSUInteger currentOffset = offset;
    
    // Read NumEntries (12 bits)
    if (currentOffset + 12 > bits.length) {
        [self.logger error:@"Range encoding too short, missing NumEntries"];
        return @NO;
    }
    
    NSInteger numEntries = [self readInt:bits offset:currentOffset length:12];
    currentOffset += 12;
    
    // Check each range entry
    for (NSInteger i = 0; i < numEntries; i++) {
        if (currentOffset + 1 > bits.length) {
            [self.logger error:[NSString stringWithFormat:@"Range encoding too short at entry %ld", (long)i]];
            return @NO;
        }
        
        BOOL isRange = [bits characterAtIndex:currentOffset] == '1';
        currentOffset += 1;
        
        if (!isRange) {
            // Single vendor ID (16 bits)
            if (currentOffset + 16 > bits.length) {
                [self.logger error:@"Range encoding too short for single vendor ID"];
                return @NO;
            }
            
            NSInteger singleVendorId = [self readInt:bits offset:currentOffset length:16];
            currentOffset += 16;
            
            if (singleVendorId == vendorId) {
                return @YES;
            }
        } else {
            // Range: StartVendorId (16 bits) + EndVendorId (16 bits)
            if (currentOffset + 32 > bits.length) {
                [self.logger error:@"Range encoding too short for vendor range"];
                return @NO;
            }
            
            NSInteger startVendorId = [self readInt:bits offset:currentOffset length:16];
            currentOffset += 16;
            
            NSInteger endVendorId = [self readInt:bits offset:currentOffset length:16];
            currentOffset += 16;
            
            if (vendorId >= startVendorId && vendorId <= endVendorId) {
                return @YES;
            }
        }
    }
    
    // Vendor not found in any range
    return @NO;
}

#pragma mark - GPP Resolution Methods (Legacy Fallback)

- (nullable NSNumber *)resolveGdprApplies {
    // Priority 1: GPP SID contains 2 (EU TCF section)
    NSArray<NSNumber *> *sids = [self gppSid];
    if (sids && [sids containsObject:@(kGPPSidEuTcf)]) {
        [self.logger debug:@"GDPR applies resolved from GPP SID containing 2"];
        return @YES;
    }
    
    // Priority 2: Legacy IABTCF_gdprApplies flag
    return [self gdprApplies];
}

- (nullable NSString *)resolveGppString {
    // Priority 1: GPP string from CMP
    NSString *gpp = [self gppString];
    if (gpp && gpp.length > 0) {
        return gpp;
    }
    
    // Priority 2: Construct from legacy TC string
    NSString *legacyTcString = [self tcString];
    if (legacyTcString && legacyTcString.length > 0) {
        // Construct GPP format: "[GPP_HEADER_TCF_EU_ONLY]~[tcString]"
        NSString *constructedGpp = [NSString stringWithFormat:@"%@~%@", kGPPHeaderTcfEuOnly, legacyTcString];
        [self.logger debug:[NSString stringWithFormat:@"Constructed GPP from legacy TCF: %@", constructedGpp]];
        return constructedGpp;
    }
    
    return nil;
}

- (nullable NSArray<NSNumber *> *)resolveGppSid {
    // Priority 1: GPP SID from CMP
    NSArray<NSNumber *> *sids = [self gppSid];
    if (sids && sids.count > 0) {
        return sids;
    }
    
    // Priority 2: [2] when constructing from legacy TC string
    NSString *legacyTcString = [self tcString];
    if (legacyTcString && legacyTcString.length > 0) {
        [self.logger debug:@"Constructed GPP SID [2] from legacy TCF presence"];
        return @[@(kGPPSidEuTcf)];
    }
    
    return nil;
}

#pragma mark - Publisher API Methods

- (void)setGppString:(nullable NSString *)gppString {
    [self.logger debug:[NSString stringWithFormat:@"Setting GPP string: %@", gppString ?: @"(cleared)"]];
    if (gppString) {
        [self.userDefaults setObject:gppString forKey:kIABGPP_GppString];
    } else {
        [self.userDefaults removeObjectForKey:kIABGPP_GppString];
    }
    [self.userDefaults synchronize];
}

- (void)setGppSid:(nullable NSArray<NSNumber *> *)gppSid {
    [self.logger debug:[NSString stringWithFormat:@"Setting GPP SID: %@", gppSid ?: @"(cleared)"]];
    if (gppSid && gppSid.count > 0) {
        // Convert to underscore-delimited string (matching Android format)
        NSMutableArray<NSString *> *sidStrings = [NSMutableArray array];
        for (NSNumber *sid in gppSid) {
            [sidStrings addObject:[sid stringValue]];
        }
        NSString *sidString = [sidStrings componentsJoinedByString:@"_"];
        [self.userDefaults setObject:sidString forKey:kIABGPP_GppSID];
    } else {
        [self.userDefaults removeObjectForKey:kIABGPP_GppSID];
    }
    [self.userDefaults synchronize];
}

@end

#pragma mark - Error Reporting Helper

@implementation CLXConsentProvider (ErrorReporting)

- (void)reportException:(NSException *)exception context:(NSDictionary<NSString *, NSString *> *)context {
    // Only report if error reporter was injected
    if (self.errorReporter) {
        [self.errorReporter reportException:exception context:context];
    }
}

@end
