#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSDKConfigPlacement.h>
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
@property (nonatomic, copy) NSString *appBundle;
@property (nonatomic, copy) NSString *accountId;
@property (nonatomic, copy) NSString *hashedGeoIp;

@property (nonatomic, strong) CLXLogger *logger;

// Private method declarations
- (nullable id)resolveArrayLookup:(NSDictionary *)data segment:(NSString *)segment withFullResponseData:(NSDictionary *)fullData;
- (nullable id)resolveConditionValue:(NSString *)expression withBidResponseData:(nullable NSDictionary *)bidResponseData auctionId:(nullable NSString *)auctionId;

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
    NSMutableDictionary *configDict = [NSMutableDictionary dictionary];
    if (config.accountID) configDict[@"accountID"] = config.accountID;
    if (config.organizationID) configDict[@"organizationID"] = config.organizationID;
    if (config.sessionID) configDict[@"sessionID"] = config.sessionID;
    
    // Store placements data as an array to support array lookup syntax like config.placements[id=...]
    if (config.placements && config.placements.count > 0) {
        NSMutableArray *placementsArray = [NSMutableArray array];
        [self.logger debug:[NSString stringWithFormat:@"Processing %lu placements from config", (unsigned long)config.placements.count]];
        for (id placementObj in config.placements) {
            // Verify it's a CLXSDKConfigPlacement object
            if ([placementObj isKindOfClass:[CLXSDKConfigPlacement class]]) {
                CLXSDKConfigPlacement *placement = (CLXSDKConfigPlacement *)placementObj;
                NSMutableDictionary *placementData = [NSMutableDictionary dictionary];
                if (placement.id) placementData[@"id"] = placement.id;
                if (placement.name) placementData[@"name"] = placement.name;
                if (placement.dealId) placementData[@"externalId"] = placement.dealId;
                [placementsArray addObject:placementData];
                [self.logger debug:[NSString stringWithFormat:@"Stored placement: id=%@, name=%@", placement.id, placement.name]];
            } else {
                [self.logger debug:[NSString stringWithFormat:@"Skipping placement - unexpected type: %@", NSStringFromClass([placementObj class])]];
            }
        }
        configDict[@"placements"] = placementsArray;
        [self.logger debug:[NSString stringWithFormat:@"Total placements stored: %lu", (unsigned long)placementsArray.count]];
    }
    
    self.configDataMap = [configDict copy];
    
    [self.logger debug:[NSString stringWithFormat:@"Config set with %lu tracking fields, %lu placements", 
                        (unsigned long)self.tracking.count,
                        (unsigned long)(config.placements ? config.placements.count : 0)]];
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
                abTestGroup:(NSString *)abTestGroup
                  appBundle:(NSString *)appBundle {
    self.sessionId = sessionId;
    self.sdkVersion = sdkVersion;
    self.deviceType = deviceType;
    self.abTestGroup = abTestGroup;
    self.appBundle = appBundle;
    
    [self.logger debug:[NSString stringWithFormat:@"Session constant data set - bundle: %@", appBundle ?: @"(none)"]];
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
    
    for (NSString *field in self.tracking) {
        id resolvedValue = [self resolveField:auctionId field:field];
        NSString *stringValue = resolvedValue ? [resolvedValue description] : @"";
        [values addObject:stringValue];
    }
    
    NSString *payload = [values componentsJoinedByString:@";"];
    [self.logger debug:[NSString stringWithFormat:@"Built payload with %lu fields for auction: %@", (unsigned long)values.count, auctionId]];
    
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
        return [self resolveConfigField:auctionId field:field];
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
    } else if ([field isEqualToString:@"sdk.deviceTypeName"]) {
        // Return string for analytics ("phone", "tablet", "unknown")
        return DeviceTypeToString([CLXSystemInformation shared].deviceType);
    } else if ([field isEqualToString:@"sdk.appBundle"] || [field isEqualToString:@"sdk.app.bundle"]) {
        return self.appBundle;
    } else if ([field isEqualToString:@"sdk.responseTimeMillis"]) {
        // This should be set dynamically per auction
        NSMutableDictionary *auctionSdkMap = self.sdkMap[auctionId];
        return auctionSdkMap[field];
    } else if ([field isEqualToString:@"sdk.loopIndex"]) {
        return self.auctionedLoopIndex[auctionId];
    } else if ([field isEqualToString:@"sdk.ifa"]) {
        // Privacy logic implementation
        CLXPrivacyService *privacyService = [CLXPrivacyService sharedInstance];
        
        // Check if personal data should be cleared due to privacy settings
        if ([privacyService shouldClearPersonalData]) {
            [self.logger debug:@"[CLXTrackingFieldResolver] Privacy settings require clearing personal data - using session ID"];
            return self.sessionId ?: @"";
        }
        
        // Check DNT (Do Not Track) flag from bid request (OpenRTB field names)
        NSDictionary *requestData = self.requestDataMap[auctionId];
        NSDictionary *device = [requestData objectForKey:@"device"];
        NSNumber *dntValue = [device objectForKey:@"dnt"];
        BOOL isLimitedAdTrackingEnabled = [dntValue intValue] == 1;
        
        if (isLimitedAdTrackingEnabled) {
            [self.logger debug:@"[CLXTrackingFieldResolver] DNT flag is set - using privacy-safe identifier"];
            
            // Use hashed user ID if available
            NSString *hashedUserId = [privacyService hashedUserId];
            if (hashedUserId && hashedUserId.length > 0) {
                [self.logger debug:@"[CLXTrackingFieldResolver] Using hashed user ID"];
                return hashedUserId;
            }
            
            // Fallback to hashed geo IP
            if (self.hashedGeoIp && self.hashedGeoIp.length > 0) {
                [self.logger debug:@"[CLXTrackingFieldResolver] Using hashed geo IP"];
                return self.hashedGeoIp;
            }
            
            [self.logger debug:@"[CLXTrackingFieldResolver] No privacy-safe identifiers available - returning empty string"];
            return @"";
        }
        
        // Normal case: return the actual IFA
        NSString *ifa = [self resolveNestedField:requestData path:@"device.ifa"];
        [self.logger debug:[NSString stringWithFormat:@"Using device IFA: %@", ifa ? @"(present)" : @"(none)"]];
        return ifa;
    } else {
        // Check auction-specific SDK parameters
        NSMutableDictionary *auctionSdkMap = self.sdkMap[auctionId];
        return auctionSdkMap[field];
    }
}

- (nullable id)resolveBidRequestField:(NSString *)auctionId field:(NSString *)field {
    // General case: resolve using dot notation
    NSDictionary *requestData = self.requestDataMap[auctionId];
    if (!requestData) {
        return nil;
    }
    
    NSString *path = [field stringByReplacingOccurrencesOfString:@"bidRequest." withString:@""];
    
    // Debug logging for country field
    if ([path isEqualToString:@"device.geo.country"]) {
        NSDictionary *device = requestData[@"device"];
        NSDictionary *geo = device[@"geo"];
        [self.logger debug:[NSString stringWithFormat:@"[CLXTrackingFieldResolver] Resolving device.geo.country: '%@' (device:%@, geo:%@)", 
                           geo[@"country"], device ? @"✓" : @"✗", geo ? @"✓" : @"✗"]];
    }
    
    return [self resolveNestedField:requestData path:path];
}

- (nullable id)resolveBidField:(NSString *)auctionId field:(NSString *)field {
    NSString *bidId = self.loadedBidMap[auctionId];
    if (!bidId) {
        [self.logger debug:[NSString stringWithFormat:@"No bidId found for auction: %@", auctionId]];
        return nil;
    }
    
    NSDictionary *responseData = self.responseDataMap[auctionId];
    if (!responseData) {
        [self.logger debug:[NSString stringWithFormat:@"No response data for auction: %@", auctionId]];
        return nil;
    }
    
    // Find the winning bid object in seatbid array
    NSArray *seatbids = responseData[@"seatbid"];
    if (![seatbids isKindOfClass:[NSArray class]]) {
        [self.logger debug:[NSString stringWithFormat:@"No seatbid array found in response"]];
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
                break;
            }
        }
        if (bidObj) break;
    }
    
    if (!bidObj) {
        [self.logger debug:[NSString stringWithFormat:@"No bid object found for bidId: %@", bidId]];
        return nil;
    }
    
    // Handle specific bid fields directly with proper JSON access
    if ([field isEqualToString:@"bid.ext.prebid.meta.adaptercode"]) {
        // Direct access to the bidder field
        id result = bidObj[@"ext"][@"prebid"][@"meta"][@"adaptercode"];
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
            // Find the matching impression by impid
            NSDictionary *requestData = self.requestDataMap[auctionId];
            NSArray *impressions = requestData[@"imp"];
            if ([impressions isKindOfClass:[NSArray class]]) {
                for (NSDictionary *imp in impressions) {
                    if ([imp[@"id"] isEqualToString:impid]) {
                        NSArray *formats = imp[@"banner"][@"format"];
                        if ([formats isKindOfClass:[NSArray class]] && formats.count > 0) {
                            width = formats[0][@"w"];
                        }
                        break;
                    }
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
            // Find the matching impression by impid
            NSDictionary *requestData = self.requestDataMap[auctionId];
            NSArray *impressions = requestData[@"imp"];
            if ([impressions isKindOfClass:[NSArray class]]) {
                for (NSDictionary *imp in impressions) {
                    if ([imp[@"id"] isEqualToString:impid]) {
                        NSArray *formats = imp[@"banner"][@"format"];
                        if ([formats isKindOfClass:[NSArray class]] && formats.count > 0) {
                            height = formats[0][@"h"];
                        }
                        break;
                    }
                }
            }
        }
        return height;
    }
    
    if ([field isEqualToString:@"bid.dealid"]) {
        id dealid = bidObj[@"dealid"];
        
        // If not found in bid object, look in the resolved request debug data
        if (!dealid) {
            NSDictionary *responseData = self.responseDataMap[auctionId];
            if (responseData) {
                // Look for deal ID in ext.debug.rounds.1.resolvedrequest.imp[0].ext.prebid.bidder.meta.line_items[0].deal.id
                id debugData = responseData[@"ext"][@"debug"][@"rounds"][@"1"][@"resolvedrequest"][@"imp"];
                if ([debugData isKindOfClass:[NSArray class]] && [(NSArray *)debugData count] > 0) {
                    NSDictionary *imp = debugData[0];
                    id lineItems = imp[@"ext"][@"prebid"][@"bidder"][@"meta"][@"line_items"];
                    if ([lineItems isKindOfClass:[NSArray class]] && [(NSArray *)lineItems count] > 0) {
                        NSDictionary *lineItem = lineItems[0];
                        dealid = lineItem[@"deal"][@"id"];
                    }
                }
            }
        }
        
        return dealid;
    }
    
    // Fallback to the old string manipulation approach for other fields
    NSString *path;
    if ([field hasPrefix:@"bid."]) {
        path = [field substringFromIndex:4]; // Remove "bid." (4 characters)
    } else {
        path = field;
    }
    
    return [self resolveNestedField:bidObj path:path];
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

- (nullable id)resolveConfigField:(NSString *)auctionId field:(NSString *)field {
    if ([field isEqualToString:@"config.testGroupName"]) {
        return self.abTestGroup;
    }
    
    // General config field resolution with auction context for dynamic expressions
    NSString *path = [field stringByReplacingOccurrencesOfString:@"config." withString:@""];
    return [self resolveNestedField:self.configDataMap path:path withFullResponseData:nil auctionId:auctionId];
}

- (nullable id)resolveBidResponseField:(NSString *)auctionId field:(NSString *)field {
    NSDictionary *responseData = self.responseDataMap[auctionId];
    if (!responseData) {
        return nil;
    }
    
    NSString *path = [field stringByReplacingOccurrencesOfString:@"bidResponse." withString:@""];
    return [self resolveNestedField:responseData path:path withFullResponseData:responseData auctionId:auctionId];
}

/**
 * Resolves nested field paths using dot notation with support for array lookups
 * Supports complex array conditions like: participants[rank=${bid.ext.cloudx.rank}]
 * Equivalent to Android's resolveNestedField method
 */
- (nullable id)resolveNestedField:(id)current path:(NSString *)path {
    return [self resolveNestedField:current path:path withFullResponseData:nil];
}

/**
 * Resolves nested field paths with auction context
 */
- (nullable id)resolveNestedField:(id)current path:(NSString *)path withFullResponseData:(nullable NSDictionary *)fullResponseData auctionId:(nullable NSString *)auctionId {
    // Smart path splitting that handles array lookup expressions with dots inside
    NSArray<NSString *> *segments = [self splitPathIntoSegments:path];

    
    for (NSString *segment in segments) {

        
        // Check if this segment contains array lookup syntax like: participants[rank=${bid.ext.cloudx.rank}]
        if ([segment containsString:@"["] && [segment containsString:@"]"]) {
            current = [self resolveArrayLookup:current segment:segment withFullResponseData:fullResponseData auctionId:auctionId];
            if (!current) {
                return nil;
            }
        } else {
            // Handle simple array access - if current is array, take first element
            if ([current isKindOfClass:[NSArray class]]) {
                NSArray *array = (NSArray *)current;
                current = array.count > 0 ? array[0] : nil;
            }
            
            // Handle dictionary access
            if ([current isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)current;
                current = dict[segment];
            } else {
                return nil;
            }
        }
        
        if (!current) {
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

/**
 * Splits a path into segments while preserving array lookup expressions
 * Handles cases like: ext.cloudx.auction.participants[rank=${bid.ext.cloudx.rank}].lineItemId
 */
- (NSArray<NSString *> *)splitPathIntoSegments:(NSString *)path {
    NSMutableArray<NSString *> *segments = [NSMutableArray array];
    NSInteger start = 0;
    NSInteger bracketDepth = 0;
    
    for (NSInteger i = 0; i < path.length; i++) {
        unichar c = [path characterAtIndex:i];
        
        if (c == '[') {
            bracketDepth++;
        } else if (c == ']') {
            bracketDepth--;
        } else if (c == '.' && bracketDepth == 0) {
            // Only split on dots that are not inside brackets
            NSString *segment = [path substringWithRange:NSMakeRange(start, i - start)];
            if (segment.length > 0) {
                [segments addObject:segment];
            }
            start = i + 1;
        }
    }
    
    // Add the last segment
    if (start < path.length) {
        NSString *segment = [path substringFromIndex:start];
        if (segment.length > 0) {
            [segments addObject:segment];
        }
    }
    
    return [segments copy];
}

/**
 * Resolves nested field paths using dot notation with support for array lookups
 * Supports complex array conditions like: participants[rank=${bid.ext.cloudx.rank}]
 * Passes full response data context for resolving dynamic expressions
 */
- (nullable id)resolveNestedField:(id)current path:(NSString *)path withFullResponseData:(nullable NSDictionary *)fullResponseData {
    return [self resolveNestedField:current path:path withFullResponseData:fullResponseData auctionId:nil];
}

/**
 * Resolves array lookup with conditions like: participants[rank=${bid.ext.cloudx.rank}]
 * Extracts the array name, condition field, and condition value, then finds matching element
 */
- (nullable id)resolveArrayLookup:(id)current segment:(NSString *)segment {
    return [self resolveArrayLookup:current segment:segment withFullResponseData:nil];
}

/**
 * Resolves array lookup with auction context
 */
- (nullable id)resolveArrayLookup:(id)current segment:(NSString *)segment withFullResponseData:(nullable NSDictionary *)fullResponseData auctionId:(nullable NSString *)auctionId {
    // Parse segment like: participants[rank=${bid.ext.cloudx.rank}]
    NSRange bracketStart = [segment rangeOfString:@"["];
    NSRange bracketEnd = [segment rangeOfString:@"]"];
    
    if (bracketStart.location == NSNotFound || bracketEnd.location == NSNotFound) {
        [self.logger debug:[NSString stringWithFormat:@"Invalid array lookup syntax: %@", segment]];
        return nil;
    }
    
    NSString *arrayName = [segment substringToIndex:bracketStart.location];
    NSString *condition = [segment substringWithRange:NSMakeRange(bracketStart.location + 1, 
                                                                  bracketEnd.location - bracketStart.location - 1)];
    
    // Get the array from current object
    if (![current isKindOfClass:[NSDictionary class]]) {
        [self.logger debug:@"Current is not a dictionary for array lookup"];
        return nil;
    }
    
    NSDictionary *dict = (NSDictionary *)current;
    NSArray *array = dict[arrayName];
    if (![array isKindOfClass:[NSArray class]]) {
        [self.logger debug:[NSString stringWithFormat:@"No array found for key: %@", arrayName]];
        return nil;
    }
    
    // Parse condition like: rank=${bid.ext.cloudx.rank}
    NSArray *conditionParts = [condition componentsSeparatedByString:@"="];
    if (conditionParts.count != 2) {
        [self.logger debug:[NSString stringWithFormat:@"Invalid condition syntax: %@", condition]];
        return nil;
    }
    
    NSString *conditionField = conditionParts[0];
    NSString *conditionValueExpression = conditionParts[1];
    
    // Resolve the condition value (e.g., ${bid.ext.cloudx.rank})
    // Use full response data if available, otherwise fall back to current context
    NSDictionary *contextForResolution = fullResponseData ?: dict;
    id conditionValue = [self resolveConditionValue:conditionValueExpression withBidResponseData:contextForResolution auctionId:auctionId];
    
    // Find matching element in array
    for (NSDictionary *element in array) {
        if (![element isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        id elementValue = element[conditionField];
        
        if ([self valuesAreEqual:elementValue to:conditionValue]) {
            return element;
        }
    }
    
    [self.logger debug:[NSString stringWithFormat:@"No matching element found for condition %@=%@", conditionField, conditionValue]];
    return nil;
}

/**
 * Resolves array lookup with conditions like: participants[rank=${bid.ext.cloudx.rank}]
 * Extracts the array name, condition field, and condition value, then finds matching element
 * Uses full response data context for resolving dynamic expressions
 */
- (nullable id)resolveArrayLookup:(id)current segment:(NSString *)segment withFullResponseData:(nullable NSDictionary *)fullResponseData {
    return [self resolveArrayLookup:current segment:segment withFullResponseData:fullResponseData auctionId:nil];
}

/**
 * Resolves condition values like ${bid.ext.cloudx.rank}
 */
- (nullable id)resolveConditionValue:(NSString *)expression {
    return [self resolveConditionValue:expression withBidResponseData:nil];
}

/**
 * Resolves condition values like ${bid.ext.cloudx.rank} with auction context
 */
- (nullable id)resolveConditionValue:(NSString *)expression withBidResponseData:(nullable NSDictionary *)bidResponseData auctionId:(nullable NSString *)auctionId {
    if ([expression hasPrefix:@"${"] && [expression hasSuffix:@"}"]) {
        // Extract the field path from ${...}
        NSString *fieldPath = [expression substringWithRange:NSMakeRange(2, expression.length - 3)];
        
        // Handle bid.ext.cloudx.rank by looking it up in the bid response data
        if ([fieldPath isEqualToString:@"bid.ext.cloudx.rank"]) {
            // Try to resolve from the actual bid response data if available
            if (bidResponseData) {
                id rankValue = [self resolveNestedField:bidResponseData path:@"ext.cloudx.rank"];
                if (rankValue) {
                    return rankValue;
                }
            }
            
            // If we have an auction ID, try to get the actual bid response data
            if (auctionId) {
                NSDictionary *responseData = self.responseDataMap[auctionId];
                if (responseData) {
                    // Look for the winning bid's rank in the bid response
                    // In most auction scenarios, the winning bid has rank 1
                    id rankValue = [self resolveNestedField:responseData path:@"ext.cloudx.rank"];
                    if (rankValue) {
                        return rankValue;
                    }
                }
            }
            
            // Fallback: In array lookup scenarios, the winning bid rank is conventionally 1
            // This matches the typical auction behavior where rank 1 = winner
            return @1;
        }
        
        // For other field paths, try using the full resolveField method if we have auctionId
        // This handles bidRequest.*, bid.*, config.*, bidResponse.*, and sdk.* fields
        if (auctionId) {
            id result = [self resolveField:auctionId field:fieldPath];
            if (result) {
                return result;
            }
        }
        
        // Fallback: try to resolve from the bid response data
        if (bidResponseData) {
            id result = [self resolveNestedField:bidResponseData path:fieldPath];
            if (result) {
                return result;
            }
        }
        
        // Try to resolve from auction-specific response data if available
        if (auctionId) {
            NSDictionary *responseData = self.responseDataMap[auctionId];
            if (responseData) {
                id result = [self resolveNestedField:responseData path:fieldPath];
                if (result) {
                    return result;
                }
            }
        }
        
        // For other field paths, return nil as we don't have full context resolution yet
        [self.logger debug:[NSString stringWithFormat:@"Unsupported field path in condition: %@", fieldPath]];
        return nil;
    }
    
    // Direct value (not an expression)
    return expression;
}

/**
 * Resolves condition values like ${bid.ext.cloudx.rank} with context data
 */
- (nullable id)resolveConditionValue:(NSString *)expression withBidResponseData:(nullable NSDictionary *)bidResponseData {
    return [self resolveConditionValue:expression withBidResponseData:bidResponseData auctionId:nil];
}

/**
 * Compares two values for equality, handling different types appropriately
 */
- (BOOL)valuesAreEqual:(id)value1 to:(id)value2 {
    if (value1 == nil && value2 == nil) return YES;
    if (value1 == nil || value2 == nil) return NO;
    
    // Handle numeric comparisons
    if ([value1 isKindOfClass:[NSNumber class]] && [value2 isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value1 isEqualToNumber:(NSNumber *)value2];
    }
    
    // Handle string/number cross-comparisons
    if ([value1 isKindOfClass:[NSNumber class]] && [value2 isKindOfClass:[NSString class]]) {
        return [[(NSNumber *)value1 stringValue] isEqualToString:(NSString *)value2];
    }
    
    if ([value1 isKindOfClass:[NSString class]] && [value2 isKindOfClass:[NSNumber class]]) {
        return [(NSString *)value1 isEqualToString:[(NSNumber *)value2 stringValue]];
    }
    
    // Default object equality
    return [value1 isEqual:value2];
}

#pragma mark - Win/Loss Field Resolution

- (nullable id)resolveField:(NSString *)fieldPath forAuction:(NSString *)auctionId {
    // Handle SDK-level constants
    if ([fieldPath isEqualToString:@"sdk.loopIndex"]) {
        NSNumber *loopIndex = self.auctionedLoopIndex[auctionId];
        return loopIndex ? [loopIndex stringValue] : nil;
    }
    
    // Delegate to existing field resolution logic
    return [self resolveField:auctionId field:fieldPath];
}

@end
