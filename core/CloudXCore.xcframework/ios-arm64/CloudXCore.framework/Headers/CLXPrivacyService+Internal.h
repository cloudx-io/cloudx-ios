/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

// Internal accessors for typed access to consent values, kept out of the public surface.

#import <CloudXCore/CLXPrivacyService.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPrivacyService (Internal)
- (nullable NSString *)gdprConsentString;
- (nullable NSNumber *)gdprApplies;
/// Like shouldClearPersonalData but ignores ATT status. Use for ATT-exempt identifiers (IDFV).
- (BOOL)shouldClearPersonalDataIgnoringATT;
@end

NS_ASSUME_NONNULL_END
