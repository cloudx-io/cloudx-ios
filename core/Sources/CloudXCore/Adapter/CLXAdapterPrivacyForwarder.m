/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAdapterPrivacyForwarder.h>
#import <CloudXCore/CLXAdapterPrivacyHandler.h>
#import <CloudXCore/CLXAdapterPrivacySettings.h>
#import <CloudXCore/CLXPrivacyConsentResolver.h>
#import <CloudXCore/CLXPrivacyConsent.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXManualPrivacyState.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXAdNetwork.h>
#import <CloudXCore/CLXLogger.h>

/// IAB privacy keys that trigger a push when changed in NSUserDefaults.
/// Matches Android's IAB_PRIVACY_KEYS set in AdapterPrivacyForwarder.
static NSSet<NSString *> *CLXIABPrivacyKeys(void) {
    static NSSet<NSString *> *keys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys = [NSSet setWithObjects:
            kCLXPrivacyGDPRConsentKey,  // IABTCF_TCString
            kCLXPrivacyGDPRAppliesKey,  // IABTCF_gdprApplies
            kCLXPrivacyCCPAPrivacyKey,  // IABUSPrivacy_String
            kIABGPP_GppString,          // IABGPP_HDR_GppString
            kIABGPP_GppSID,             // IABGPP_GppSID
            nil];
    });
    return keys;
}

@interface CLXAdapterPrivacyForwarder ()
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) NSArray<id<CLXAdapterPrivacyHandler>> *handlers;
@property (nonatomic, assign) BOOL observing;
@end

@implementation CLXAdapterPrivacyForwarder

+ (instancetype)sharedInstance {
    static CLXAdapterPrivacyForwarder *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXAdapterPrivacyForwarder"];
        _handlers = [self discoverHandlers];
        _observing = NO;
        [self startObserving];
    }
    return self;
}

- (void)dealloc {
    [self stop];
}

#pragma mark - Handler Discovery

- (NSArray<id<CLXAdapterPrivacyHandler>> *)discoverHandlers {
    NSMutableArray<id<CLXAdapterPrivacyHandler>> *discovered = [NSMutableArray array];

    for (CLXAdNetwork adapterName in CLXAllAdNetworks()) {
        NSString *className = CLXAdNetworkClassName(adapterName);
        NSString *handlerClassName = [NSString stringWithFormat:@"CLX%@PrivacyHandler", className];

        Class handlerClass = NSClassFromString(handlerClassName);
        if (handlerClass && [handlerClass conformsToProtocol:@protocol(CLXAdapterPrivacyHandler)]) {
            id<CLXAdapterPrivacyHandler> handler = [[handlerClass alloc] init];
            [discovered addObject:handler];
            [self.logger info:[NSString stringWithFormat:@"Discovered privacy handler: %@", handlerClassName]];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"Privacy handler not found for adapter: %@", adapterName]];
        }
    }

    [self.logger info:[NSString stringWithFormat:@"Privacy handler discovery complete: %lu handler(s)", (unsigned long)discovered.count]];
    return [discovered copy];
}

#pragma mark - Push Privacy Settings

- (void)pushCurrentPrivacySettings {
    CLXConsentProvider *provider = [CLXConsentProvider sharedInstance];
    CLXManualPrivacyState *manualState = [CLXManualPrivacyState sharedInstance];

    // GDPR: IAB resolver → manual fallback (matches Android resolveHasUserConsent)
    NSNumber *hasUserConsent = [CLXPrivacyConsentResolver resolveIabGdprConsent:provider];
    if (hasUserConsent == nil) {
        hasUserConsent = manualState.hasUserConsent;
    }

    // CCPA: GPP US sections → legacy CCPA → manual fallback (matches Android resolveIsDoNotSell)
    NSNumber *doNotSell = nil;
    NSArray<NSNumber *> *gppSid = [provider gppSid];
    if (gppSid) {
        // Try SID 8 (US-CA) first, then SID 7 (US-National) — no geo gating, adapters handle their own geo logic
        for (NSNumber *sid in @[@(8), @(7)]) {
            if ([gppSid containsObject:sid]) {
                CLXPrivacyConsent *consent = [provider decodeGppForTarget:sid];
                if (consent) {
                    doNotSell = @([consent requiresPiiRemoval]);
                    break;
                }
            }
        }
    }
    if (doNotSell == nil) {
        doNotSell = [CLXPrivacyConsentResolver resolveIabUsPrivacyDoNotSell:[NSUserDefaults standardUserDefaults]];
    }
    if (doNotSell == nil) {
        doNotSell = manualState.doNotSell;
    }

    CLXAdapterPrivacySettings *settings = [[CLXAdapterPrivacySettings alloc] initWithHasUserConsent:hasUserConsent
                                                                                         doNotSell:doNotSell
                                                                               manualHasUserConsent:manualState.hasUserConsent
                                                                                     manualDoNotSell:manualState.doNotSell];

    [self.logger debug:[NSString stringWithFormat:@"Pushing privacy settings to %lu handler(s): %@",
                        (unsigned long)self.handlers.count, settings]];

    for (id<CLXAdapterPrivacyHandler> handler in self.handlers) {
        @try {
            [handler updatePrivacySettings:settings];
        } @catch (NSException *exception) {
            [self.logger error:[NSString stringWithFormat:@"Failed to push privacy to %@: %@",
                                NSStringFromClass([handler class]), exception.reason]];
        }
    }
}

#pragma mark - NSUserDefaults Observation (KVO on IAB keys)

- (void)startObserving {
    if (self.observing) return;
    self.observing = YES;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *key in CLXIABPrivacyKeys()) {
        [defaults addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
    }
    [self.logger debug:@"Started observing IAB privacy keys in NSUserDefaults"];
}

- (void)stop {
    if (!self.observing) return;
    self.observing = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *key in CLXIABPrivacyKeys()) {
        [defaults removeObserver:self forKeyPath:key];
    }
    [self.logger debug:@"Stopped observing IAB privacy keys in NSUserDefaults"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if ([CLXIABPrivacyKeys() containsObject:keyPath]) {
        [self.logger debug:[NSString stringWithFormat:@"IAB privacy key changed: %@", keyPath]];
        [self pushCurrentPrivacySettings];
    }
}

@end
