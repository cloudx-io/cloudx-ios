//
//  CLXInMobiPrivacyHandler.m
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#if __has_include(<CloudXInMobiAdapter/CLXInMobiPrivacyHandler.h>)
#import <CloudXInMobiAdapter/CLXInMobiPrivacyHandler.h>
#else
#import "CLXInMobiPrivacyHandler.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdapterPrivacySettings.h>
#import <InMobiSDK/InMobiSDK.h>

@interface CLXInMobiPrivacyHandler ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXInMobiPrivacyHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXInMobiPrivacyHandler"];
    }
    return self;
}

- (void)updatePrivacySettings:(CLXAdapterPrivacySettings *)settings {
    [self.logger debug:[NSString stringWithFormat:@"Updating InMobi privacy: manualConsent=%@, manualDoNotSell=%@",
                        settings.manualHasUserConsent ?: @"nil", settings.manualDoNotSell ?: @"nil"]];

    // InMobi GDPR consent — must send as "true"/"false" string per InMobi SDK docs
    @try {
        NSMutableDictionary<NSString *, id> *consentDict = [NSMutableDictionary dictionaryWithCapacity:2];
        if (settings.manualHasUserConsent != nil) {
            consentDict[IMCommonConstants.IM_PARTNER_GDPR_CONSENT_AVAILABLE] = [settings.manualHasUserConsent boolValue] ? @"true" : @"false";
        }
        [IMSdk setPartnerGDPRConsent:consentDict];
        [self.logger debug:[NSString stringWithFormat:@"InMobi partner GDPR consent set: %@", consentDict]];
    } @catch (NSException *exception) {
        [self.logger error:[NSString stringWithFormat:@"Failed to set InMobi GDPR consent: %@", exception.reason]];
    }

    // InMobi CCPA do-not-sell
    if (settings.manualDoNotSell != nil) {
        @try {
            [IMPrivacyCompliance setDoNotSell:[settings.manualDoNotSell boolValue]];
            [self.logger debug:[NSString stringWithFormat:@"InMobi doNotSell set: %@", [settings.manualDoNotSell boolValue] ? @"YES" : @"NO"]];
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"Failed to set InMobi doNotSell: %@", exception.reason]];
        }
    }
}

@end
