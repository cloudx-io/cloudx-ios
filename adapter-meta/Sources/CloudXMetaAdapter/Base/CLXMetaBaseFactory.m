//
//  CLXMetaBaseFactory.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-12-19.
//

#if __has_include(<CloudXMetaAdapter/CLXMetaBaseFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBaseFactory.h>
#else
#import "CLXMetaBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@implementation CLXMetaBaseFactory

+ (NSString *)resolveMetaPlacementID:(NSDictionary<NSString *, NSString *> *)extras fallbackAdId:(NSString *)adId logger:(CLXLogger *)logger {
    // Try to get the Meta placement ID from adapter extras
    NSString *metaPlacementID = extras[@"placement_id"];
    
    if (!metaPlacementID || metaPlacementID.length == 0) {
        metaPlacementID = adId; // Fallback to original behavior
        [logger debug:[NSString stringWithFormat:@"🔧 No placement_id found in adapter extras, using fallback: %@", adId]];
    } else {
        [logger debug:[NSString stringWithFormat:@"✅ Using placement ID from adapter extras: %@", metaPlacementID]];
    }
    
    return metaPlacementID;
}

@end
