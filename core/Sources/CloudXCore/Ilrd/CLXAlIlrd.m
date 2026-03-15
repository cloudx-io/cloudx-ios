/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAlIlrd.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXAlIlrd ()
@property (nonatomic, copy) NSString *accountName;
@property (nonatomic, copy, nullable) CLXIlrdEventCallback eventCallback;
@property (nonatomic, assign) BOOL subscribed;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXAlIlrd

@synthesize platform = _platform;

- (instancetype)initWithAccountName:(NSString *)accountName {
    self = [super init];
    if (self) {
        _accountName = [accountName copy];
        _platform = CLXIlrdPlatformAl;
        _subscribed = NO;
        _logger = [[CLXLogger alloc] initWithCategory:@"AlIlrd"];
    }
    return self;
}

#pragma mark - Snake Case Conversion

- (NSString *)accountNameAsSnakeCase {
    if (_accountName.length == 0) {
        return @"";
    }

    NSMutableString *result = [NSMutableString string];
    NSUInteger length = _accountName.length;

    for (NSUInteger i = 0; i < length; i++) {
        unichar ch = [_accountName characterAtIndex:i];

        if (ch == ' ') {
            [result appendString:@"_"];
            continue;
        }

        /*
         * Insert underscore only at lowercase->uppercase boundaries.
         * Matches Android regex: ([a-z])([A-Z]) -> $1_$2
         */
        if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:ch] && i > 0) {
            unichar prev = [_accountName characterAtIndex:i - 1];
            if ([[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:prev]) {
                [result appendString:@"_"];
            }
        }

        NSString *charStr = [NSString stringWithCharacters:&ch length:1];
        [result appendString:[charStr lowercaseString]];
    }

    return [result copy];
}

- (NSString *)communicatorIdentifier {
    return [self accountNameAsSnakeCase];
}

#pragma mark - CLXIlrdProvider

- (BOOL)subscribeWithError:(NSError **)outError {
    @synchronized (self) {
        if (_subscribed) {
            [self.logger debug:@"Already subscribed to ILRD events"];
            return YES;
        }
    }

    Class communicatorClass = NSClassFromString(@"ALCCommunicator");
    if (!communicatorClass) {
        [self.logger error:@"Communicator class not found"];
        if (outError) {
            *outError = [NSError errorWithDomain:@"CLXAlIlrd"
                                            code:1
                                        userInfo:@{NSLocalizedDescriptionKey: @"Communicator class not found. Is the mediation SDK integrated?"}];
        }
        return NO;
    }

    SEL defaultCommunicatorSel = NSSelectorFromString(@"defaultCommunicator");
    if (![communicatorClass respondsToSelector:defaultCommunicatorSel]) {
        [self.logger error:@"Communicator does not respond to defaultCommunicator"];
        if (outError) {
            *outError = [NSError errorWithDomain:@"CLXAlIlrd"
                                            code:2
                                        userInfo:@{NSLocalizedDescriptionKey: @"Communicator defaultCommunicator not available"}];
        }
        return NO;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id communicator = [communicatorClass performSelector:defaultCommunicatorSel];
#pragma clang diagnostic pop

    if (!communicator) {
        [self.logger error:@"Communicator defaultCommunicator returned nil"];
        if (outError) {
            *outError = [NSError errorWithDomain:@"CLXAlIlrd"
                                            code:3
                                        userInfo:@{NSLocalizedDescriptionKey: @"Communicator defaultCommunicator returned nil"}];
        }
        return NO;
    }

    SEL subscribeSel = NSSelectorFromString(@"subscribe:forTopic:");
    if (![communicator respondsToSelector:subscribeSel]) {
        [self.logger error:@"Communicator does not respond to subscribe:forTopic:"];
        if (outError) {
            *outError = [NSError errorWithDomain:@"CLXAlIlrd"
                                            code:4
                                        userInfo:@{NSLocalizedDescriptionKey: @"Communicator does not support subscribe:forTopic:"}];
        }
        return NO;
    }

    /*
     * Subscribe to the max_revenue_events topic.
     * Using NSInvocation because performSelector: only supports up to 2 object arguments.
     *
     * The invocation is outside @synchronized to avoid deadlock: the communicator
     * may synchronously fire didReceiveMessage: which also acquires this lock.
     */
    NSMethodSignature *sig = [communicator methodSignatureForSelector:subscribeSel];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:communicator];
    [invocation setSelector:subscribeSel];
    id subscriber = self;
    NSString *topic = @"max_revenue_events";
    [invocation setArgument:&subscriber atIndex:2];
    [invocation setArgument:&topic atIndex:3];
    [invocation invoke];

    @synchronized (self) {
        _subscribed = YES;
    }
    [self.logger debug:@"Subscribed to ILRD events"];
    return YES;
}

- (BOOL)unsubscribeWithError:(NSError **)outError {
    @synchronized (self) {
        if (!_subscribed) {
            return YES;
        }
    }

    Class communicatorClass = NSClassFromString(@"ALCCommunicator");
    if (!communicatorClass) {
        return YES;
    }

    SEL defaultCommunicatorSel = NSSelectorFromString(@"defaultCommunicator");
    if (![communicatorClass respondsToSelector:defaultCommunicatorSel]) {
        return YES;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id communicator = [communicatorClass performSelector:defaultCommunicatorSel];
#pragma clang diagnostic pop

    if (!communicator) {
        @synchronized (self) {
            _subscribed = NO;
        }
        return YES;
    }

    SEL unsubscribeSel = NSSelectorFromString(@"unsubscribe:forTopic:");
    if ([communicator respondsToSelector:unsubscribeSel]) {
        NSMethodSignature *sig = [communicator methodSignatureForSelector:unsubscribeSel];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setTarget:communicator];
        [invocation setSelector:unsubscribeSel];
        id subscriber = self;
        NSString *topic = @"max_revenue_events";
        [invocation setArgument:&subscriber atIndex:2];
        [invocation setArgument:&topic atIndex:3];
        [invocation invoke];
    }

    @synchronized (self) {
        _subscribed = NO;
    }
    [self.logger debug:@"Unsubscribed from ILRD events"];
    return YES;
}

- (void)setEventCallback:(nullable CLXIlrdEventCallback)callback {
    @synchronized (self) {
        _eventCallback = [callback copy];
    }
}

#pragma mark - ALCSubscriber Protocol (implemented dynamically)

- (void)didReceiveMessage:(id)message {
    NSDictionary *data = nil;

    /*
     * Extract data dictionary from the message.
     * The message object has a `data` property containing the revenue event fields.
     */
    if ([message respondsToSelector:NSSelectorFromString(@"data")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id rawData = [message performSelector:NSSelectorFromString(@"data")];
#pragma clang diagnostic pop
        if ([rawData isKindOfClass:[NSDictionary class]]) {
            data = (NSDictionary *)rawData;
        }
    }

    if (!data) {
        [self.logger error:@"Received ILRD message with no data"];
        return;
    }

    NSMutableDictionary<NSString *, id> *event = [NSMutableDictionary dictionary];

    /* Required fields */
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    event[@"timestamp"] = @((long long)(timestamp * 1000));
    event[@"platform"] = @"AppLovin";

    NSNumber *revenue = data[@"revenue"];
    if ([revenue isKindOfClass:[NSNumber class]]) {
        event[@"revenue"] = revenue;
    }

    /* Optional fields -- camelCase keys matching Android */
    NSString *precision = data[@"precision"];
    if ([precision isKindOfClass:[NSString class]] && precision.length > 0) {
        event[@"precision"] = precision;
    }

    NSString *countryCode = data[@"country_code"];
    if ([countryCode isKindOfClass:[NSString class]] && countryCode.length > 0) {
        event[@"countryCode"] = countryCode;
    }

    NSString *networkName = data[@"network_name"];
    if ([networkName isKindOfClass:[NSString class]] && networkName.length > 0) {
        event[@"networkName"] = networkName;
    }

    NSString *maxAdUnitId = data[@"max_ad_unit_id"];
    if ([maxAdUnitId isKindOfClass:[NSString class]] && maxAdUnitId.length > 0) {
        event[@"adUnitId"] = maxAdUnitId;
    }

    NSString *placementId = data[@"third_party_ad_placement_id"];
    if ([placementId isKindOfClass:[NSString class]] && placementId.length > 0) {
        event[@"thirdPartyAdPlacementId"] = placementId;
    }

    NSString *adFormat = data[@"ad_format"];
    if ([adFormat isKindOfClass:[NSString class]] && adFormat.length > 0) {
        event[@"adFormat"] = [self normalizeAdFormat:adFormat];
    }

    NSString *creativeId = data[@"creative_id"];
    if ([creativeId isKindOfClass:[NSString class]] && creativeId.length > 0) {
        event[@"creativeId"] = creativeId;
    }

    NSString *networkPlacement = data[@"network_placement"];
    if ([networkPlacement isKindOfClass:[NSString class]] && networkPlacement.length > 0) {
        event[@"networkPlacement"] = networkPlacement;
    }

    NSString *userSegment = data[@"user_segment"];
    if ([userSegment isKindOfClass:[NSString class]] && userSegment.length > 0) {
        event[@"userSegment"] = userSegment;
    }

    NSString *eventId = data[@"id"];
    if ([eventId isKindOfClass:[NSString class]] && eventId.length > 0) {
        event[@"id"] = eventId;
    }

    [self.logger debug:[NSString stringWithFormat:@"ILRD event received: revenue=%@, adFormat=%@",
                        revenue, adFormat ?: @"(nil)"]];

    CLXIlrdEventCallback callback;
    @synchronized (self) {
        callback = _eventCallback;
    }
    if (callback) {
        callback([event copy]);
    }
}

/**
 * Normalizes raw AppLovin ad format strings to CX ad type names.
 * Matches Android's `String.toAdType()` in ApplovinIlrd.kt.
 */
- (NSString *)normalizeAdFormat:(NSString *)raw {
    NSString *upper = [raw uppercaseString];
    if ([upper isEqualToString:@"INTER"]) return @"interstitial";
    if ([upper isEqualToString:@"REWARDED"]) return @"rewarded";
    if ([upper isEqualToString:@"BANNER"]) return @"banner";
    if ([upper isEqualToString:@"MREC"]) return @"mrec";
    [self.logger error:[NSString stringWithFormat:@"Unknown ad format: %@", raw]];
    return raw;
}

@end
