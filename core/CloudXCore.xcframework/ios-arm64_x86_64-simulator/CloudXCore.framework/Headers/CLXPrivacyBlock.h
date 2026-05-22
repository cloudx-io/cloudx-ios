/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Identifiers, device privacy signals, and IAB consent strings. gdprApplies is tri-state (nil/YES/NO). */
@interface CLXPrivacyBlock : NSObject

@property (nonatomic, copy, nullable) NSString *deviceIFA;
@property (nonatomic, copy, nullable) NSString *deviceIFV;
@property (nonatomic, copy, nullable) NSString *installId;
@property (nonatomic, copy, nullable) NSNumber *deviceDNT;
@property (nonatomic, copy, nullable) NSNumber *deviceLMT;
@property (nonatomic, copy, nullable) NSNumber *gdprApplies;
@property (nonatomic, copy, nullable) NSString *tcString;
@property (nonatomic, copy, nullable) NSString *usPrivacy;
@property (nonatomic, copy, nullable) NSString *gpp;
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *gppSid;

- (NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
