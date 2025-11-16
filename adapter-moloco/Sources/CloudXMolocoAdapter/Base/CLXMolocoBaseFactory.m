//
//  CLXMolocoBaseFactory.m
//  CloudXMolocoAdapter
//
//  Created by CloudX on 2024.
//

#if __has_include(<CloudXMolocoAdapter/CLXMolocoBaseFactory.h>)
#import <CloudXMolocoAdapter/CLXMolocoBaseFactory.h>
#else
#import "CLXMolocoBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@implementation CLXMolocoBaseFactory

+ (NSString *)resolveMolocoPlacementID:(NSDictionary<NSString *, NSString *> *)extras 
                          fallbackAdId:(NSString *)adId 
                                logger:(CLXLogger *)logger {
    NSString *molocoPlacementID = extras[@"moloco_placement_id"];
    
    if (molocoPlacementID && molocoPlacementID.length > 0) {
        [logger debug:[NSString stringWithFormat:@"Using Moloco placement ID from extras: %@", molocoPlacementID]];
        return molocoPlacementID;
    }
    
    [logger debug:[NSString stringWithFormat:@"Using fallback ad ID: %@", adId]];
    return adId;
}

@end

