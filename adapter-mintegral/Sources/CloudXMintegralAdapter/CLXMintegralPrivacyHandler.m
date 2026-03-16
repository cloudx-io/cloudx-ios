//
//  CLXMintegralPrivacyHandler.m
//  CloudXMintegralAdapter
//
//  Created by CloudX Team.
//

#import "CLXMintegralPrivacyHandler.h"

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAdapterPrivacySettings.h>
#import <MTGSDK/MTGSDK.h>

@interface CLXMintegralPrivacyHandler ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMintegralPrivacyHandler

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralPrivacyHandler"];
    }
    return self;
}

- (void)updatePrivacySettings:(CLXAdapterPrivacySettings *)settings {
    [self.logger debug:[NSString stringWithFormat:@"Updating Mintegral privacy: manualConsent=%@, manualDoNotSell=%@",
                        settings.manualHasUserConsent ?: @"nil", settings.manualDoNotSell ?: @"nil"]];

    MTGSDK *mtgSDK = [MTGSDK sharedInstance];

    // Mintegral GDPR consent
    if (settings.manualHasUserConsent != nil) {
        @try {
            mtgSDK.consentStatus = [settings.manualHasUserConsent boolValue];
            [self.logger debug:[NSString stringWithFormat:@"Mintegral consent status set: %@", settings.manualHasUserConsent]];
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"Failed to set Mintegral consent: %@", exception.reason]];
        }
    }

    // Mintegral CCPA do-not-track — only set to YES, never reset to NO
    if (settings.manualDoNotSell != nil && [settings.manualDoNotSell boolValue]) {
        @try {
            mtgSDK.doNotTrackStatus = YES;
            [self.logger debug:@"Mintegral doNotTrack status set: YES"];
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"Failed to set Mintegral doNotTrack: %@", exception.reason]];
        }
    }
}

@end
