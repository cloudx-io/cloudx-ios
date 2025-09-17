#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@interface CLXTrackingFieldResolver ()

@property (nonatomic, strong) NSArray<NSString *> *tracking;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *requestDataMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *responseDataMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *loadedBidMap;
@property (nonatomic, strong) NSDictionary *configDataMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSString *> *> *sdkMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *auctionedLoopIndex;

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy) NSString *deviceType;
@property (nonatomic, copy) NSString *abTestGroup;
@property (nonatomic, copy) NSString *accountId;
@property (nonatomic, copy) NSString *hashedGeoIp;

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
        _loadedBidMap = [NSMutableDictionary dictionary];
        _sdkMap = [NSMutableDictionary dictionary];
        _auctionedLoopIndex = [NSMutableDictionary dictionary];
        _logger = [[CLXLogger alloc] initWithCategory:@"TrackingFieldResolver"];
    }
    return self;
}

- (void)setConfig:(CLXSDKConfigResponse *)config {
    self.accountId = config.accountID;
    self.tracking = config.tracking;
    
    // Store raw config as dictionary for field resolution
    // Note: In a real implementation, you'd want to store the original JSON
    // For now, we'll create a basic representation
    NSMutableDictionary *configDict = [NSMutableDictionary dictionary];
    if (config.accountID) configDict[@"accountID"] = config.accountID;
    if (config.organizationID) configDict[@"organizationID"] = config.organizationID;
    if (config.sessionID) configDict[@"sessionID"] = config.sessionID;
    self.configDataMap = [configDict copy];
    
    [self.logger debug:[NSString stringWithFormat:@"Config set with %lu tracking fields", (unsigned long)self.tracking.count]];
}

- (void)setRequestData:(NSString *)auctionId bidRequestJSON:(NSDictionary *)bidRequestJSON {
    self.requestDataMap[auctionId] = bidRequestJSON;
    [self.logger debug:[NSString stringWithFormat:@"Request data set for auction: %@", auctionId]];
}

- (void)setResponseData:(NSString *)auctionId bidResponseJSON:(NSDictionary *)bidResponseJSON {
    self.responseDataMap[auctionId] = bidResponseJSON;
    [self.logger debug:[NSString stringWithFormat:@"Response data set for auction: %@", auctionId]];
}

- (void)saveLoadedBid:(NSString *)auctionId bidId:(NSString *)bidId {
    self.loadedBidMap[auctionId] = bidId;
    [self.logger debug:[NSString stringWithFormat:@"Loaded bid saved: %@ for auction: %@", bidId, auctionId]];
}

- (void)setLoopIndex:(NSString *)auctionId loopIndex:(NSInteger)loopIndex {
    self.auctionedLoopIndex[auctionId] = @(loopIndex);
    [self.logger debug:[NSString stringWithFormat:@"Loop index set: %ld for auction: %@", (long)loopIndex, auctionId]];
}

- (void)setSessionConstData:(NSString *)sessionId
                 sdkVersion:(NSString *)sdkVersion
                 deviceType:(NSString *)deviceType
                abTestGroup:(NSString *)abTestGroup {
    self.sessionId = sessionId;
    self.sdkVersion = sdkVersion;
    self.deviceType = deviceType;
    self.abTestGroup = abTestGroup;
    
    [self.logger debug:@"Session constant data set"];
}

- (void)setHashedGeoIp:(nullable NSString *)hashedGeoIp {
    _hashedGeoIp = [hashedGeoIp copy];
    [self.logger debug:[NSString stringWithFormat:@"Set hashed geo IP: %@", hashedGeoIp ? @"(present)" : @"(none)"]];
}

- (nullable NSString *)buildPayload:(NSString *)auctionId {
    if (!self.tracking || self.tracking.count == 0) {
        [self.logger debug:@"No tracking configuration available"];
        return nil;
    }
    
    NSMutableArray<NSString *> *values = [NSMutableArray array];
    
    [self.logger debug:[NSString stringWithFormat:@"🔍 [PAYLOAD DEBUG] Building payload for auction: %@ with %lu fields", auctionId, (unsigned long)self.tracking.count]];
    
    for (NSString *field in self.tracking) {
        id resolvedValue = [self resolveField:auctionId field:field];
        NSString *stringValue = resolvedValue ? [resolvedValue description] : @"";
        [self.logger debug:[NSString stringWithFormat:@"🔍 [FieldDebug] %@ = '%@'", field, stringValue]];
        [values addObject:stringValue];
    }
    
    NSString *payload = [values componentsJoinedByString:@";"];
    [self.logger debug:[NSString stringWithFormat:@"Built payload with %lu fields for auction: %@ - Payload: %@", (unsigned long)values.count, auctionId, payload]];
    
    return payload;
}

- (nullable NSString *)getAccountId {
    return self.accountId;
}

- (void)clear {
    [self.requestDataMap removeAllObjects];
    [self.responseDataMap removeAllObjects];
    [self.loadedBidMap removeAllObjects];
    [self.sdkMap removeAllObjects];
    [self.auctionedLoopIndex removeAllObjects];
    
    [self.logger debug:@"All tracking data cleared"];
}

#pragma mark - Private Methods

/**
 * Resolves a field path dynamically using dot notation
 * Equivalent to Android's resolveField method
 */
- (nullable id)resolveField:(NSString *)auctionId field:(NSString *)field {
    // Handle SDK fields
    if ([field hasPrefix:@"sdk."]) {
        return [self resolveSdkField:auctionId field:field];
    }
    
    // Handle bid request fields
    if ([field hasPrefix:@"bidRequest."]) {
        return [self resolveBidRequestField:auctionId field:field];
    }
    
    // Handle bid response fields
    if ([field hasPrefix:@"bid."]) {
        return [self resolveBidField:auctionId field:field];
    }
    
    // Handle config fields
    if ([field hasPrefix:@"config."]) {
        return [self resolveConfigField:field];
    }
    
    // Handle bid response fields
    if ([field hasPrefix:@"bidResponse."]) {
        return [self resolveBidResponseField:auctionId field:field];
    }
    
    [self.logger debug:[NSString stringWithFormat:@"Unknown field prefix: %@", field]];
    return nil;
}

- (nullable id)resolveSdkField:(NSString *)auctionId field:(NSString *)field {
    if ([field isEqualToString:@"sdk.sessionId"]) {
        return self.sessionId;
    } else if ([field isEqualToString:@"sdk.releaseVersion"]) {
        return self.sdkVersion ?: @"1.0.0";
    } else if ([field isEqualToString:@"sdk.deviceType"]) {
        return self.deviceType;
    } else if ([field isEqualToString:@"sdk.responseTimeMillis"]) {
        // This should be set dynamically per auction
        NSMutableDictionary *auctionSdkMap = self.sdkMap[auctionId];
        return auctionSdkMap[field];
    } else {
        // Check auction-specific SDK parameters
        NSMutableDictionary *auctionSdkMap = self.sdkMap[auctionId];
        return auctionSdkMap[field];
    }
}

- (nullable id)resolveBidRequestField:(NSString *)auctionId field:(NSString *)field {
    // Handle special cases first
    if ([field isEqualToString:@"bidRequest.loopIndex"]) {
        return self.auctionedLoopIndex[auctionId];
    }
    
    if ([field isEqualToString:@"bidRequest.device.ifa"]) {
        // Privacy logic implementation matching Android behavior
        CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
        
        // Check if personal data should be cleared due to privacy settings
        if ([privacyService shouldClearPersonalData]) {
            [self.logger debug:@"🔒 [CLXTrackingFieldResolver] Privacy settings require clearing personal data - using session ID"];
            return self.sessionId ?: @"";
        }
        
        // Check DNT (Do Not Track) flag from bid request
        NSDictionary *requestData = self.requestDataMap[auctionId];
        NSDictionary *device = [requestData objectForKey:kCLXCoreDeviceKey];
        NSNumber *dntValue = [device objectForKey:kCLXCoreDntKey];
        BOOL isLimitedAdTrackingEnabled = [dntValue intValue] == 1;
        
        if (isLimitedAdTrackingEnabled) {
            [self.logger debug:@"🔒 [CLXTrackingFieldResolver] DNT flag is set - using privacy-safe identifier"];
            
            // Use hashed user ID if available
            NSString *hashedUserId = [privacyService hashedUserId];
            if (hashedUserId && hashedUserId.length > 0) {
                [self.logger debug:@"🔒 [CLXTrackingFieldResolver] Using hashed user ID"];
                return hashedUserId;
            }
            
            // Fallback to hashed geo IP
            if (self.hashedGeoIp && self.hashedGeoIp.length > 0) {
                [self.logger debug:@"🔒 [CLXTrackingFieldResolver] Using hashed geo IP"];
                return self.hashedGeoIp;
            }
            
            [self.logger debug:@"🔒 [CLXTrackingFieldResolver] No privacy-safe identifiers available - returning empty string"];
            return @"";
        }
        
        // Normal case: return the actual IFA
        NSString *ifa = [self resolveNestedField:requestData path:@"device.ifa"];
        [self.logger debug:[NSString stringWithFormat:@"✅ [CLXTrackingFieldResolver] Using device IFA: %@", ifa ? @"(present)" : @"(none)"]];
        return ifa;
    }
    
    // General case: resolve using dot notation
    NSDictionary *requestData = self.requestDataMap[auctionId];
    if (!requestData) {
        return nil;
    }
    
    NSString *path = [field stringByReplacingOccurrencesOfString:@"bidRequest." withString:@""];
    return [self resolveNestedField:requestData path:path];
}

- (nullable id)resolveBidField:(NSString *)auctionId field:(NSString *)field {
    NSString *bidId = self.loadedBidMap[auctionId];
    if (!bidId) {
        [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] No bidId found for auction: %@", auctionId]];
        return nil;
    }
    
    NSDictionary *responseData = self.responseDataMap[auctionId];
    if (!responseData) {
        [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] No response data for auction: %@", auctionId]];
        return nil;
    }
    
    // Find the winning bid object in seatbid array
    NSArray *seatbids = responseData[@"seatbid"];
    if (![seatbids isKindOfClass:[NSArray class]]) {
        [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] No seatbid array found in response"]];
        return nil;
    }
    
    NSDictionary *bidObj = nil;
    NSString *impid = nil;
    for (NSDictionary *seatbid in seatbids) {
        NSArray *bids = seatbid[@"bid"];
        if (![bids isKindOfClass:[NSArray class]]) continue;
        
        for (NSDictionary *bid in bids) {
            if ([bid[@"id"] isEqualToString:bidId]) {
                bidObj = bid;
                impid = bid[@"impid"];  // 🔗 Get the impression ID
                [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Found bid object for bidId: %@", bidId]];
                break;
            }
        }
        if (bidObj) break;
    }
    
    if (!bidObj) {
        [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] No bid object found for bidId: %@", bidId]];
        return nil;
    }
    
    // Handle dimension fields by looking up in bid request
    // Many ad networks (like Meta) don't return w/h in bid response because:
    // 1. OpenRTB w/h fields are optional in bid responses
    // 2. Dimensions are already known from the original bid request
    // 3. Reduces response payload size
    // 4. Meta uses -1 for flexible width, but we want actual rendered dimensions
    // Solution: Use impid to link back to bid request and get actual display dimensions
    if ([field isEqualToString:@"bid.w"] || [field isEqualToString:@"bid.h"]) {
        return [self resolveBidDimensionField:auctionId field:field impid:impid];
    }
    
    // Handle field name mappings for OpenRTB vs tracking field names
    // Handle specific bid fields directly with proper JSON access
    if ([field isEqualToString:@"bid.ext.prebid.meta.adaptercode"]) {
        // Direct access to the bidder field
        id result = bidObj[@"ext"][@"prebid"][@"meta"][@"adaptercode"];
        [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Direct access to bidder: %@", result ?: @"(nil)"]];
        return result;
    }
    
    if ([field isEqualToString:@"bid.creativeId"]) {
        // Map bid.creativeId to bid.crid (OpenRTB standard field name)
        return bidObj[@"crid"];
    }
    
    if ([field isEqualToString:@"bid.price"]) {
        return bidObj[@"price"];
    }
    
    if ([field isEqualToString:@"bid.w"]) {
        // Get width from bid response or fallback to request data
        id width = bidObj[@"w"];
        if (!width) {
            // Fallback: get from original bid request impression format
            NSDictionary *requestData = self.requestDataMap[auctionId];
            NSArray *impressions = requestData[@"imp"];
            if ([impressions isKindOfClass:[NSArray class]] && impressions.count > 0) {
                NSDictionary *imp = impressions[0];
                NSArray *formats = imp[@"banner"][@"format"];
                if ([formats isKindOfClass:[NSArray class]] && formats.count > 0) {
                    width = formats[0][@"w"];
                }
            }
        }
        return width;
    }
    
    if ([field isEqualToString:@"bid.h"]) {
        // Get height from bid response or fallback to request data
        id height = bidObj[@"h"];
        if (!height) {
            // Fallback: get from original bid request impression format
            NSDictionary *requestData = self.requestDataMap[auctionId];
            NSArray *impressions = requestData[@"imp"];
            if ([impressions isKindOfClass:[NSArray class]] && impressions.count > 0) {
                NSDictionary *imp = impressions[0];
                NSArray *formats = imp[@"banner"][@"format"];
                if ([formats isKindOfClass:[NSArray class]] && formats.count > 0) {
                    height = formats[0][@"h"];
                }
            }
        }
        return height;
    }
    
    if ([field isEqualToString:@"bid.dealid"]) {
        return bidObj[@"dealid"];
    }
    
    // Fallback to the old string manipulation approach for other fields
    NSString *path;
    if ([field hasPrefix:@"bid."]) {
        path = [field substringFromIndex:4]; // Remove "bid." (4 characters)
    } else {
        path = field;
    }
    
    [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Fallback path resolution for '%@' -> '%@'", field, path]];
    id result = [self resolveNestedField:bidObj path:path];
    [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Result for %@: %@", field, result ?: @"(nil)"]];
    return result;
}

/**
 * Resolves bid dimension fields (w/h) by looking them up in the original bid request.
 * 
 * This is necessary because many ad networks don't include width/height in their bid responses:
 * - Meta returns w:-1 (flexible width) or omits w/h entirely
 * - Dimensions are redundant since they're already in the bid request
 * - This approach gives us the actual rendered dimensions (e.g., 320x50)
 * 
 * Process:
 * 1. Use the winning bid's impid to find the matching impression in bid request
 * 2. Extract dimensions from imp.banner.format[0].{w,h}
 * 3. Return the actual display dimensions that were requested and rendered
 *
 * @param auctionId The auction identifier to look up request data
 * @param field The field being resolved ("bid.w" or "bid.h")
 * @param impid The impression ID from the winning bid response
 * @return The width or height value from the bid request, or nil if not found
 */
- (nullable id)resolveBidDimensionField:(NSString *)auctionId field:(NSString *)field impid:(NSString *)impid {
    if (!impid) {
        return nil;
    }
    
    NSDictionary *requestData = self.requestDataMap[auctionId];
    if (!requestData) {
        return nil;
    }
    
    // Find the matching impression in the bid request
    NSArray *impressions = requestData[@"imp"];
    if (![impressions isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSDictionary *matchingImp = nil;
    for (NSDictionary *imp in impressions) {
        if ([imp[@"id"] isEqualToString:impid]) {
            matchingImp = imp;
            break;
        }
    }
    
    if (!matchingImp) {
        return nil;
    }
    
    // Get dimensions from banner format
    NSDictionary *banner = matchingImp[@"banner"];
    if (![banner isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSArray *formats = banner[@"format"];
    if (![formats isKindOfClass:[NSArray class]] || formats.count == 0) {
        return nil;
    }
    
    // Use the first format (primary size)
    NSDictionary *format = formats[0];
    if (![format isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    if ([field isEqualToString:@"bid.w"]) {
        return format[@"w"];
    } else if ([field isEqualToString:@"bid.h"]) {
        return format[@"h"];
    }
    
    return nil;
}

- (nullable id)resolveConfigField:(NSString *)field {
    if ([field isEqualToString:@"config.testGroupName"]) {
        return self.abTestGroup;
    }
    
    // General config field resolution
    NSString *path = [field stringByReplacingOccurrencesOfString:@"config." withString:@""];
    return [self resolveNestedField:self.configDataMap path:path];
}

- (nullable id)resolveBidResponseField:(NSString *)auctionId field:(NSString *)field {
    NSDictionary *responseData = self.responseDataMap[auctionId];
    if (!responseData) {
        return nil;
    }
    
    NSString *path = [field stringByReplacingOccurrencesOfString:@"bidResponse." withString:@""];
    return [self resolveNestedField:responseData path:path];
}

/**
 * Resolves nested field paths using dot notation
 * Equivalent to Android's resolveNestedField method
 */
- (nullable id)resolveNestedField:(id)current path:(NSString *)path {
    NSArray<NSString *> *segments = [path componentsSeparatedByString:@"."];
    [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Resolving path: %@ with %lu segments", path, (unsigned long)segments.count]];
    
    for (NSString *segment in segments) {
        [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Processing segment: %@, current type: %@", segment, [current class]]];
        
        // Handle array access - if current is array, take first element
        if ([current isKindOfClass:[NSArray class]]) {
            NSArray *array = (NSArray *)current;
            current = array.count > 0 ? array[0] : nil;
            [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Array access, took first element: %@", current ?: @"(nil)"]];
        }
        
        // Handle dictionary access
        if ([current isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)current;
            current = dict[segment];
            [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Dict access [%@] = %@", segment, current ?: @"(nil)"]];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Current is not a dictionary, returning nil"]];
            return nil;
        }
        
        if (!current) {
            [self.logger debug:[NSString stringWithFormat:@"🔍 [CLXTrackingFieldResolver] Current is nil after segment %@, returning nil", segment]];
            return nil;
        }
    }
    
    // If final result is array, take first element
    if ([current isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)current;
        current = array.count > 0 ? array[0] : nil;
    }
    
    return current;
}

@end
