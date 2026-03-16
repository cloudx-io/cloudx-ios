//
//  CLXVunglePrivacyHandler.m
//  CloudXVungleAdapter
//
//  Created by CloudX Team.
//

#import "CLXVunglePrivacyHandler.h"

#if __has_include(<CloudXCore/CloudXCore.h>)
#import <CloudXCore/CloudXCore.h>
#else
@import CloudXCore;
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdapterPrivacySettings.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

@interface CLXVunglePrivacyHandler ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXVunglePrivacyHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXVunglePrivacyHandler"];
    }
    return self;
}

- (void)updatePrivacySettings:(CLXAdapterPrivacySettings *)settings {
    [self.logger debug:[NSString stringWithFormat:@"Updating Vungle privacy: manualConsent=%@, manualDoNotSell=%@",
                        settings.manualHasUserConsent ?: @"nil", settings.manualDoNotSell ?: @"nil"]];

    // Vungle GDPR consent
    if (settings.manualHasUserConsent != nil) {
        @try {
            [VunglePrivacySettings setGDPRStatus:[settings.manualHasUserConsent boolValue]];
            [VunglePrivacySettings setGDPRMessageVersion:@""];
            [self.logger debug:[NSString stringWithFormat:@"Vungle GDPR status set: %@", [settings.manualHasUserConsent boolValue] ? @"YES" : @"NO"]];
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"Failed to set Vungle GDPR status: %@", exception.reason]];
        }
    }

    // Vungle CCPA — invert doNotSell to match Vungle's CCPA convention
    if (settings.manualDoNotSell != nil) {
        @try {
            [VunglePrivacySettings setCCPAStatus:![settings.manualDoNotSell boolValue]];
            [self.logger debug:[NSString stringWithFormat:@"Vungle CCPA status set: %@", ![settings.manualDoNotSell boolValue] ? @"YES" : @"NO"]];
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"Failed to set Vungle CCPA status: %@", exception.reason]];
        }
    }
}

@end
