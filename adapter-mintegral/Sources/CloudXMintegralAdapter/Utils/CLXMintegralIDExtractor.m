//
//  CLXMintegralIDExtractor.m
//  CloudXMintegralAdapter
//
//  Shared utility for extracting Mintegral IDs from bid response extras.
//

#import "CLXMintegralIDExtractor.h"
#import <CloudXCore/CLXLogger.h>

#pragma mark - CLXMintegralIDResult

@implementation CLXMintegralIDResult

- (instancetype)initWithPlacementID:(NSString *)placementID
                             unitID:(NSString *)unitID
                              bidID:(nullable NSString *)bidID {
    self = [super init];
    if (self) {
        _placementID = [placementID copy];
        _unitID = [unitID copy];
        _bidID = [bidID copy];
    }
    return self;
}

@end

#pragma mark - CLXMintegralIDExtractor

@implementation CLXMintegralIDExtractor

+ (CLXMintegralIDResult *)extractIDsFromExtras:(nullable NSDictionary *)extras
                                          adId:(nullable NSString *)adId
                                    bidIdParam:(nullable NSString *)bidIdParam
                                        logger:(nullable CLXLogger *)logger {
    
    [logger debug:[NSString stringWithFormat:@"[IDExtractor] Extracting IDs - adId:'%@', extras keys: %@",
                   adId ?: @"(nil)", extras.allKeys ?: @[]]];
    
    NSString *placementID = nil;
    NSString *unitID = nil;
    
    // Primary: Read from adapter_extras
    // Server sends three distinct fields:
    //   - placement_id: Mintegral placement ID
    //   - ad_unit_id: Mintegral ad unit ID (used for loading ads)
    //   - bid_id: Bid tracking ID
    if (extras && [extras isKindOfClass:[NSDictionary class]]) {
        placementID = extras[@"placement_id"];
        unitID = extras[@"ad_unit_id"];
        
        [logger debug:[NSString stringWithFormat:@"[IDExtractor] From extras - placement_id:'%@', ad_unit_id:'%@'",
                       placementID ?: @"(nil)", unitID ?: @"(nil)"]];
    }
    
    // Fallback: Parse from adId parameter if extras didn't have the IDs
    if ((!placementID.length || !unitID.length) && adId.length) {
        NSArray *components = [adId componentsSeparatedByString:@"_"];
        
        [logger debug:[NSString stringWithFormat:@"[IDExtractor] Parsing adId fallback - components: %@", components]];
        
        if (components.count >= 2) {
            // Format: placementID_unitID
            if (!placementID.length) {
                placementID = components[0];
            }
            if (!unitID.length) {
                unitID = components[1];
            }
        } else {
            // Single ID - use for both if missing
            if (!placementID.length) {
                placementID = adId;
            }
            if (!unitID.length) {
                unitID = adId;
            }
        }
    }
    
    // Last resort: if one is missing, use the other
    if (!placementID.length && unitID.length) {
        placementID = unitID;
    } else if (!unitID.length && placementID.length) {
        unitID = placementID;
    }
    
    // Resolve bidID: prefer bid_id from extras, fall back to parameter
    NSString *bidID = extras[@"bid_id"] ?: bidIdParam;
    
    [logger debug:[NSString stringWithFormat:@"[IDExtractor] Final - placementID:'%@', unitID:'%@', bidID:'%@'",
                   placementID ?: @"(nil)", unitID ?: @"(nil)", bidID ?: @"(nil)"]];
    
    return [[CLXMintegralIDResult alloc] initWithPlacementID:placementID ?: @""
                                                      unitID:unitID ?: @""
                                                       bidID:bidID];
}

@end
