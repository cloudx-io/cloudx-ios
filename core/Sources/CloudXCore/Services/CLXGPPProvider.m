/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXGPPProvider.m
 * @brief Implementation of GPP provider service
 * @details Handles GPP string parsing with support for US-CA and US-National sections
 */

#import <CloudXCore/CLXGPPProvider.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXErrorReporter.h>

// IAB GPP UserDefaults keys
NSString * const kIABGPP_GppString = @"IABGPP_HDR_GppString";
NSString * const kIABGPP_GppSID = @"IABGPP_GppSID";

@interface CLXGPPProvider ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong, nullable) CLXErrorReporter *errorReporter;
@end

@interface CLXGPPProvider (ErrorReporting)
- (void)reportException:(NSException *)exception context:(NSDictionary<NSString *, NSString *> *)context;
@end

@implementation CLXGPPProvider

+ (instancetype)sharedInstance {
    static CLXGPPProvider *sharedInstance = nil;
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
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXGPPProvider"];
        _userDefaults = [NSUserDefaults standardUserDefaults];
        _errorReporter = errorReporter;
    }
    return self;
}

- (nullable NSString *)gppString {
    @try {
        NSString *gppString = [self.userDefaults stringForKey:kIABGPP_GppString];
        if (gppString.length > 0) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGPPProvider] GPP string: %@", gppString]];
            return gppString;
        }
        [self.logger debug:@"📊 [CLXGPPProvider] GPP string: (none)"];
        return nil;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] Failed to read GPP string: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSArray<NSNumber *> *)gppSid {
    @try {
        NSString *rawSid = [self.userDefaults stringForKey:kIABGPP_GppSID];
        if (rawSid.length == 0) {
            [self.logger debug:@"📊 [CLXGPPProvider] GPP SID: (none)"];
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
            [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGPPProvider] GPP SID: %@", sortedSids]];
            return sortedSids;
        }
        
        [self.logger debug:@"📊 [CLXGPPProvider] GPP SID: (none - no valid values)"];
        return nil;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] Failed to parse GPP SID: %@", exception.reason]];
        return nil;
    }
}

- (nullable CLXGppConsent *)decodeGppForTarget:(nullable NSNumber *)target {
    NSString *gpp = [self gppString];
    NSArray<NSNumber *> *sids = [self gppSid];
    
    if (!gpp || !sids || sids.count == 0) {
        [self.logger debug:@"📊 [CLXGPPProvider] No GPP data available for decoding"];
        return nil;
    }
    
    if (target) {
        // Decode specific target
        CLXGppConsent *consent = [self decodeGppSection:gpp sids:sids targetSid:[target integerValue]];
        if (consent && [consent requiresPiiRemoval]) {
            [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGPPProvider] Decoded target %@ with PII removal required", target]];
            return consent;
        }
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGPPProvider] Target %@ does not require PII removal", target]];
        return nil;
    } else {
        // Auto-select: prioritize consent requiring PII removal, then first available
        NSArray<NSNumber *> *prioritySids = @[@(CLXGppTargetUSCA), @(CLXGppTargetUSNational)];
        NSMutableArray<CLXGppConsent *> *decodedConsents = [NSMutableArray array];
        
        for (NSNumber *sidNumber in prioritySids) {
            CLXGppConsent *consent = [self decodeGppSection:gpp sids:sids targetSid:[sidNumber integerValue]];
            if (consent) {
                [decodedConsents addObject:consent];
            }
        }
        
        // Find first consent requiring PII removal
        for (CLXGppConsent *consent in decodedConsents) {
            if ([consent requiresPiiRemoval]) {
                [self.logger debug:@"📊 [CLXGPPProvider] Auto-selected consent requiring PII removal"];
                return consent;
            }
        }
        
        // Return first available if none require PII removal
        if (decodedConsents.count > 0) {
            [self.logger debug:@"📊 [CLXGPPProvider] Auto-selected first available consent"];
            return decodedConsents.firstObject;
        }
        
        [self.logger debug:@"📊 [CLXGPPProvider] No decodable consent found"];
        return nil;
    }
}

- (nullable CLXGppConsent *)decodeGppSection:(NSString *)gpp sids:(NSArray<NSNumber *> *)sids targetSid:(NSInteger)targetSid {
    if (![sids containsObject:@(targetSid)]) {
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGPPProvider] SID %ld not present in GPP", (long)targetSid]];
        return nil;
    }
    
    @try {
        NSString *payload = [self selectSectionPayload:gpp sids:sids targetSid:targetSid];
        if (!payload) {
            [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] Failed to extract payload for SID %ld", (long)targetSid]];
            return nil;
        }
        
        if (targetSid == CLXGppTargetUSCA) {
            return [self decodeUsCa:payload];
        } else if (targetSid == CLXGppTargetUSNational) {
            return [self decodeUsNational:payload];
        } else {
            [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] Unsupported SID %ld", (long)targetSid]];
            return nil;
        }
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] Failed to decode SID %ld: %@", (long)targetSid, exception.reason]];
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
        [self.logger error:@"❌ [CLXGPPProvider] GPP string has no payload sections"];
        return nil;
    }
    
    // Find index of target SID in sorted SID array
    NSUInteger sidIndex = [sids indexOfObject:@(targetSid)];
    if (sidIndex == NSNotFound || sidIndex >= payloads.count) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] SID %ld index %lu out of range for %lu payloads", (long)targetSid, (unsigned long)sidIndex, (unsigned long)payloads.count]];
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

- (nullable CLXGppConsent *)decodeUsCa:(NSString *)payload {
    @try {
        NSString *bits = [self base64UrlToBits:payload];
        if (!bits) {
            [self.logger error:@"❌ [CLXGPPProvider] Failed to decode US-CA payload to bits"];
            return nil;
        }
        
        // US-CA section: saleOptOut at bit 12 (2 bits), sharingOptOut at bit 14 (2 bits)
        NSNumber *saleOptOut = [self readBits:bits start:12 length:2];
        NSNumber *sharingOptOut = [self readBits:bits start:14 length:2];
        
        CLXGppConsent *consent = [[CLXGppConsent alloc] initWithSaleOptOut:saleOptOut sharingOptOut:sharingOptOut];
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGPPProvider] US-CA decoded: %@", consent]];
        return consent;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] US-CA decode failed: %@", exception.reason]];
        return nil;
    }
}

- (nullable CLXGppConsent *)decodeUsNational:(NSString *)payload {
    @try {
        NSString *bits = [self base64UrlToBits:payload];
        if (!bits) {
            [self.logger error:@"❌ [CLXGPPProvider] Failed to decode US-National payload to bits"];
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
        
        CLXGppConsent *consent = [[CLXGppConsent alloc] initWithSaleOptOut:effectiveSaleOptOut sharingOptOut:effectiveSharingOptOut];
        [self.logger debug:[NSString stringWithFormat:@"📊 [CLXGPPProvider] US-National decoded: %@", consent]];
        return consent;
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] US-National decode failed: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSString *)base64UrlToBits:(NSString *)encoded {
    if (encoded.length == 0) return nil;
    
    @try {
        // Add padding if needed
        NSUInteger paddingLength = (4 - (encoded.length % 4)) % 4;
        NSString *paddedEncoded = [encoded stringByPaddingToLength:encoded.length + paddingLength 
                                                        withString:@"=" 
                                                   startingAtIndex:0];
        
        // Decode base64url
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:paddedEncoded 
                                                                  options:NSDataBase64DecodingIgnoreUnknownCharacters];
        if (!decodedData) {
            [self.logger error:@"❌ [CLXGPPProvider] Base64URL decoding failed"];
            return nil;
        }
        
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
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] Base64URL to bits conversion failed: %@", exception.reason]];
        return nil;
    }
}

- (nullable NSNumber *)readBits:(NSString *)bits start:(NSUInteger)start length:(NSUInteger)length {
    if (start + length > bits.length) {
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] Bit range %lu-%lu exceeds string length %lu", 
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
        [self.logger error:[NSString stringWithFormat:@"❌ [CLXGPPProvider] Exception in bit_string_parsing: %@ - %@", 
                           exception.name ?: @"unknown", exception.reason ?: @"no reason"]];
        [self reportException:exception context:@{@"operation": @"bit_string_parsing", @"start": [@(start) stringValue], @"length": [@(length) stringValue]}];
        return nil;
    }
}

#pragma mark - Publisher API Methods

- (void)setGppString:(nullable NSString *)gppString {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXGPPProvider] Setting GPP string: %@", gppString ?: @"(cleared)"]];
    if (gppString) {
        [self.userDefaults setObject:gppString forKey:kIABGPP_GppString];
    } else {
        [self.userDefaults removeObjectForKey:kIABGPP_GppString];
    }
    [self.userDefaults synchronize];
}

- (void)setGppSid:(nullable NSArray<NSNumber *> *)gppSid {
    [self.logger debug:[NSString stringWithFormat:@"🔧 [CLXGPPProvider] Setting GPP SID: %@", gppSid ?: @"(cleared)"]];
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

@implementation CLXGPPProvider (ErrorReporting)

- (void)reportException:(NSException *)exception context:(NSDictionary<NSString *, NSString *> *)context {
    // Only report if error reporter was injected
    if (self.errorReporter) {
        [self.errorReporter reportException:exception context:context];
    }
}

@end
