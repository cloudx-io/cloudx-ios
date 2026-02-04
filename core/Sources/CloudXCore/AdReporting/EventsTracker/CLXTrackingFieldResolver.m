#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXKeyValueState.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXVersion.h>

#pragma mark - Constants (matches Android companion object)

// Public constant (like Android)
NSString * const SDK_PARAM_RESPONSE_IN_MILLIS = @"sdk.responseTimeMillis";

// Private constants (matches Android companion object)
static NSString * const SDK_PARAM_APP_BUNDLE = @"sdk.app.bundle";
static NSString * const SDK_PARAM_SDK_VERSION = @"sdk.releaseVersion";
static NSString * const SDK_PARAM_PLUGIN_VERSION = @"sdk.pluginVersion";
static NSString * const SDK_PARAM_DEVICE_TYPE_NAME = @"sdk.deviceTypeName";
static NSString * const SDK_PARAM_DEVICE_TYPE_CODE = @"sdk.deviceTypeCode";
static NSString * const SDK_PARAM_SESSION_ID = @"sdk.sessionId";
static NSString * const SDK_PARAM_ABTEST_GROUP = @"sdk.testGroupName";
static NSString * const SDK_PARAM_IFA = @"sdk.ifa";

#pragma mark - NSDictionary Category (matches Android extension function)

@interface NSDictionary (ResolveNestedField)
- (nullable id)resolveNestedField:(NSString *)path;
@end

@implementation NSDictionary (ResolveNestedField)

// Matches Android: private fun Any?.resolveNestedField(path: String): Any?
- (nullable id)resolveNestedField:(NSString *)path {
    // Static regex - compile once, reuse
    static NSRegularExpression *filterRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        filterRegex = [NSRegularExpression
            regularExpressionWithPattern:@"^(\\w+)\\[(\\w+)=(.+)\\]$"
            options:0
            error:nil];
    });

    id current = self;

    for (NSString *segment in [path componentsSeparatedByString:@"."]) {
        // Check for array filter: arrayName[key=value]
        NSTextCheckingResult *filterMatch = [filterRegex
            firstMatchInString:segment
            options:0
            range:NSMakeRange(0, segment.length)];

        if (filterMatch) {
            NSString *arrayName = [segment substringWithRange:[filterMatch rangeAtIndex:1]];
            NSString *filterKey = [segment substringWithRange:[filterMatch rangeAtIndex:2]];
            NSString *filterValue = [segment substringWithRange:[filterMatch rangeAtIndex:3]];

            NSArray *arr = [current isKindOfClass:[NSDictionary class]] ? current[arrayName] : nil;
            if (![arr isKindOfClass:[NSArray class]]) return nil;

            id found = nil;
            for (NSDictionary *item in arr) {
                if ([item isKindOfClass:[NSDictionary class]] &&
                    [[item[filterKey] description] isEqualToString:filterValue]) {
                    found = item;
                    break;
                }
            }
            current = found;
            if (!current) return nil;
            continue;
        }

        // Auto-unroll arrays (like Android)
        while ([current isKindOfClass:[NSArray class]]) {
            NSArray *arr = (NSArray *)current;
            current = arr.count > 0 ? arr[0] : nil;
            if (!current) return nil;
        }

        // Navigate into dictionary
        current = [current isKindOfClass:[NSDictionary class]] ? current[segment] : nil;
        if (!current) return nil;
    }

    // Final array unroll
    if ([current isKindOfClass:[NSArray class]]) {
        NSArray *arr = (NSArray *)current;
        current = arr.count > 0 ? arr[0] : nil;
    }

    return current;
}

@end

#pragma mark - CLXTrackingFieldResolver

@interface CLXTrackingFieldResolver ()

// Data maps (matches Android)
@property (nonatomic, strong) NSArray<NSString *> *tracking;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *requestDataMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *responseDataMap;
@property (nonatomic, strong) NSDictionary *configDataMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *sdkMap;

// Session constants (matches Android constructor params)
@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy, nullable) NSString *pluginVersion;
@property (nonatomic, copy) NSString *deviceTypeName;
@property (nonatomic, assign) NSInteger deviceTypeCode;
@property (nonatomic, copy) NSString *abTestGroup;
@property (nonatomic, copy) NSString *appBundle;
@property (nonatomic, copy, nullable) NSString *hashedGeoIp;

// iOS-specific
@property (nonatomic, copy) NSString *accountId;
@property (nonatomic, strong) CLXLogger *logger;

@end

@implementation CLXTrackingFieldResolver

+ (instancetype)shared {
    static CLXTrackingFieldResolver *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXTrackingFieldResolver alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestDataMap = [NSMutableDictionary dictionary];
        _responseDataMap = [NSMutableDictionary dictionary];
        _sdkMap = [NSMutableDictionary dictionary];
        _logger = [[CLXLogger alloc] initWithCategory:@"TrackingFieldResolver"];
    }
    return self;
}

#pragma mark - Config Setup

- (void)setConfigJSON:(NSDictionary *)configJSON {
    self.configDataMap = configJSON;
    self.tracking = configJSON[@"tracking"];
    self.accountId = configJSON[@"accountID"];
}

- (void)setConfig:(CLXSDKConfigResponse *)config {
    if (config.rawJSON) {
        [self setConfigJSON:config.rawJSON];
        return;
    }
    // Legacy fallback
    self.accountId = config.accountID;
    self.tracking = config.tracking;
    NSMutableDictionary *configDict = [NSMutableDictionary dictionary];
    if (config.accountID) configDict[@"accountID"] = config.accountID;
    if (config.organizationID) configDict[@"organizationID"] = config.organizationID;
    if (config.sessionID) configDict[@"sessionID"] = config.sessionID;
    self.configDataMap = [configDict copy];
}

#pragma mark - Data Methods (matches Android)

// Matches Android: setRequestData(auctionId: String, json: JSONObject)
- (void)setRequestData:(NSString *)auctionId bidRequestJSON:(NSDictionary *)json {
    self.requestDataMap[auctionId] = json;
}

// Matches Android: setResponseData(auctionId: String, json: JSONObject)
- (void)setResponseData:(NSString *)auctionId bidResponseJSON:(NSDictionary *)json {
    self.responseDataMap[auctionId] = json;
}

// Matches Android: setSdkParam(auctionId: String, key: String, value: String)
- (void)setSdkParam:(NSString *)auctionId key:(NSString *)key value:(NSString *)value {
    NSMutableDictionary *params = self.sdkMap[auctionId];
    if (!params) {
        params = [NSMutableDictionary dictionary];
        self.sdkMap[auctionId] = params;
    }
    params[key] = value;
}

// iOS-specific: sets session constants (Android receives in constructor)
- (void)setSessionConstData:(NSString *)sessionId
                 sdkVersion:(NSString *)sdkVersion
              pluginVersion:(nullable NSString *)pluginVersion
             deviceTypeName:(NSString *)deviceTypeName
             deviceTypeCode:(NSInteger)deviceTypeCode
                abTestGroup:(NSString *)abTestGroup
                  appBundle:(NSString *)appBundle {
    self.sessionId = sessionId;
    self.sdkVersion = sdkVersion;
    self.pluginVersion = pluginVersion;
    self.deviceTypeName = deviceTypeName;
    self.deviceTypeCode = deviceTypeCode;
    self.abTestGroup = abTestGroup;
    self.appBundle = appBundle;
}

- (void)setHashedGeoIp:(nullable NSString *)hashedGeoIp {
    _hashedGeoIp = [hashedGeoIp copy];
}

#pragma mark - Payload Building (matches Android)

// Matches Android: buildPayload(auctionId: String, bidId: String? = null): String
- (nullable NSString *)buildPayload:(NSString *)auctionId bidId:(nullable NSString *)bidId {
    if (!self.tracking || self.tracking.count == 0) {
        return nil;
    }

    NSMutableArray<NSString *> *values = [NSMutableArray array];
    for (NSString *field in self.tracking) {
        id resolvedValue = [self resolveField:auctionId field:field bidId:bidId];
        // Escape semicolons in resolved values before joining (customData may contain ';')
        NSString *stringValue = resolvedValue ? [resolvedValue description] : @"";
        NSString *escapedValue = [stringValue stringByReplacingOccurrencesOfString:@";" withString:@"%3B"];
        [values addObject:escapedValue];
    }

    return [values componentsJoinedByString:@";"];
}

- (nullable NSString *)buildPayload:(NSString *)auctionId {
    return [self buildPayload:auctionId bidId:nil];
}

#pragma mark - Field Resolution (matches Android resolveField)

// Matches Android: resolveField(auctionId: String, field: String, bidId: String? = null): Any?
- (nullable id)resolveField:(NSString *)auctionId field:(NSString *)field bidId:(nullable NSString *)bidId {
    // Static regex for placeholder expansion - compile once, reuse
    static NSRegularExpression *placeholderRegex;
    static dispatch_once_t placeholderOnceToken;
    dispatch_once(&placeholderOnceToken, ^{
        placeholderRegex = [NSRegularExpression
            regularExpressionWithPattern:@"\\$\\{([^}]+)\\}"
            options:0
            error:nil];
    });

    // Placeholder expander (matches Android's expandTemplate)
    NSString * (^expandTemplate)(NSString *) = ^NSString *(NSString *template) {
        if (![template containsString:@"${"]) return template;

        NSMutableString *result = [template mutableCopy];
        NSArray *matches = [placeholderRegex matchesInString:template options:0
            range:NSMakeRange(0, template.length)];

        for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
            NSString *innerPath = [template substringWithRange:[match rangeAtIndex:1]];
            id resolved = [self resolveField:auctionId field:innerPath bidId:bidId];
            [result replaceCharactersInRange:match.range
                withString:resolved ? [resolved description] : @""];
        }
        return result;
    };

    // —— BID fields ——
    if ([field hasPrefix:@"bid."]) {
        if (!bidId) return nil;  // bidId required (like Android)

        NSArray *seatbid = self.responseDataMap[auctionId][@"seatbid"];
        if (![seatbid isKindOfClass:[NSArray class]]) return nil;

        // Find bid object by bidId
        NSDictionary *bidObj = nil;
        for (NSDictionary *seat in seatbid) {
            for (NSDictionary *bid in seat[@"bid"]) {
                if ([bid[@"id"] isEqualToString:bidId]) { bidObj = bid; break; }
            }
            if (bidObj) break;
        }
        if (!bidObj) return nil;

        NSString *expandedPath = expandTemplate([field substringFromIndex:4]);
        return [bidObj resolveNestedField:expandedPath];
    }

    // —— BID REQUEST fields ——
    if ([field hasPrefix:@"bidRequest."]) {
        NSDictionary *json = self.requestDataMap[auctionId];
        if (!json) return nil;

        NSString *expandedPath = expandTemplate([field substringFromIndex:11]);
        return [json resolveNestedField:expandedPath];
    }

    // —— CONFIG fields ——
    if ([field hasPrefix:@"config."]) {
        NSString *expandedPath = expandTemplate([field substringFromIndex:7]);
        return [self.configDataMap resolveNestedField:expandedPath];
    }

    // —— SDK fields ——
    if ([field hasPrefix:@"sdk."]) {
        if ([field isEqualToString:SDK_PARAM_SESSION_ID]) return self.sessionId;
        if ([field isEqualToString:SDK_PARAM_APP_BUNDLE]) return self.appBundle;
        if ([field isEqualToString:SDK_PARAM_SDK_VERSION]) return self.sdkVersion;
        if ([field isEqualToString:SDK_PARAM_PLUGIN_VERSION]) return self.pluginVersion;
        if ([field isEqualToString:SDK_PARAM_DEVICE_TYPE_NAME]) return self.deviceTypeName;
        if ([field isEqualToString:SDK_PARAM_DEVICE_TYPE_CODE]) return @(self.deviceTypeCode);
        if ([field isEqualToString:SDK_PARAM_IFA]) return [self handleIfaField:auctionId];
        if ([field isEqualToString:SDK_PARAM_ABTEST_GROUP]) return self.abTestGroup;
        return self.sdkMap[auctionId][field];  // Fallback to sdkMap
    }

    // —— RESPONSE fields ——
    if ([field hasPrefix:@"bidResponse."]) {
        NSDictionary *json = self.responseDataMap[auctionId];
        if (!json) return nil;

        NSString *expandedPath = expandTemplate([field substringFromIndex:12]);
        return [json resolveNestedField:expandedPath];
    }

    return nil;
}

- (nullable id)resolveField:(NSString *)auctionId field:(NSString *)field {
    return [self resolveField:auctionId field:field bidId:nil];
}

#pragma mark - Private Methods

// Matches Android: handleIfaField(auctionId: String): String?
- (nullable NSString *)handleIfaField:(NSString *)auctionId {
    if ([[CLXPrivacyService sharedInstance] shouldClearPersonalData]) {
        return self.sessionId;
    }

    NSNumber *dnt = self.requestDataMap[auctionId][@"device"][@"dnt"];
    BOOL isLimitedAdTrackingEnabled = [dnt intValue] == 1;

    if (isLimitedAdTrackingEnabled) {
        NSString *hashedUserId = [[CLXKeyValueState shared] hashedUserId];
        if (hashedUserId.length > 0) return hashedUserId;
        return self.hashedGeoIp;
    }

    return self.requestDataMap[auctionId][@"device"][@"ifa"];
}

#pragma mark - Utility Methods

- (nullable NSString *)getAccountId {
    return self.accountId;
}

- (void)clear {
    [self.requestDataMap removeAllObjects];
    [self.responseDataMap removeAllObjects];
    [self.sdkMap removeAllObjects];
}

#pragma mark - Public Field Resolution (for WinLossFieldResolver)

- (nullable id)resolveField:(NSString *)fieldPath forAuction:(NSString *)auctionId {
    return [self resolveField:auctionId field:fieldPath bidId:nil];
}

#pragma mark - Legacy Helper Methods (for test compatibility)

// Helper to get first bidId from response (for tests that don't pass bidId)
- (nullable NSString *)firstBidIdForAuction:(NSString *)auctionId {
    NSArray *seatbid = self.responseDataMap[auctionId][@"seatbid"];
    if (![seatbid isKindOfClass:[NSArray class]] || seatbid.count == 0) return nil;

    NSDictionary *firstSeat = seatbid[0];
    NSArray *bids = firstSeat[@"bid"];
    if (![bids isKindOfClass:[NSArray class]] || bids.count == 0) return nil;

    return bids[0][@"id"];
}

- (nullable id)resolveBidField:(NSString *)auctionId field:(NSString *)field {
    NSString *bidId = [self firstBidIdForAuction:auctionId];
    return [self resolveField:auctionId field:field bidId:bidId];
}

- (nullable id)resolveBidRequestField:(NSString *)auctionId field:(NSString *)field {
    return [self resolveField:auctionId field:field bidId:nil];
}

- (nullable id)resolveBidResponseField:(NSString *)auctionId field:(NSString *)field {
    return [self resolveField:auctionId field:field bidId:nil];
}

- (nullable id)resolveSdkField:(NSString *)auctionId field:(NSString *)field {
    return [self resolveField:auctionId field:field bidId:nil];
}

@end
