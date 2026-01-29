//
//  CLXMetaUtils.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaUtils.h>)
#import <CloudXMetaAdapter/CLXMetaUtils.h>
#else
#import "CLXMetaUtils.h"
#endif

#import <CloudXCore/CLXLogger.h>

@implementation CLXMetaUtils

+ (NSString *)resolveMetaPlacementID:(NSDictionary<NSString *, NSString *> *)extras
                          fallbackAdId:(NSString *)adId
                                logger:(CLXLogger *)logger {
    NSString *metaPlacementID = extras[@"placement_id"];

    if (!metaPlacementID || metaPlacementID.length == 0) {
        metaPlacementID = adId;
        [logger debug:[NSString stringWithFormat:@"No placement_id in extras, using fallback: %@", adId]];
    } else {
        [logger debug:[NSString stringWithFormat:@"Using placement ID from extras: %@", metaPlacementID]];
    }

    return metaPlacementID;
}

@end
