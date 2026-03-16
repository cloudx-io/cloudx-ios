/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAdapterPrivacySettings.h>

@implementation CLXAdapterPrivacySettings

- (instancetype)initWithHasUserConsent:(nullable NSNumber *)hasUserConsent
                             doNotSell:(nullable NSNumber *)doNotSell
                   manualHasUserConsent:(nullable NSNumber *)manualHasUserConsent
                         manualDoNotSell:(nullable NSNumber *)manualDoNotSell {
    self = [super init];
    if (self) {
        _hasUserConsent = hasUserConsent;
        _doNotSell = doNotSell;
        _manualHasUserConsent = manualHasUserConsent;
        _manualDoNotSell = manualDoNotSell;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<CLXAdapterPrivacySettings: hasUserConsent=%@, doNotSell=%@, manualHasUserConsent=%@, manualDoNotSell=%@>",
            self.hasUserConsent ?: @"nil",
            self.doNotSell ?: @"nil",
            self.manualHasUserConsent ?: @"nil",
            self.manualDoNotSell ?: @"nil"];
}

@end
