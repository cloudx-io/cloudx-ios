/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXBidResponse.h>

@interface CLXAd ()

@property (nonatomic, readwrite, nullable) NSString *placementName;
@property (nonatomic, readwrite, nullable) NSString *placementId;
@property (nonatomic, readwrite, nullable) NSString *bidder;
@property (nonatomic, readwrite, nullable) NSString *externalPlacementId;
@property (nonatomic, readwrite, nullable) NSNumber *revenue;

@end

@implementation CLXAd

- (instancetype)initWithPlacementName:(nullable NSString *)placementName
                          placementId:(nullable NSString *)placementId
                               bidder:(nullable NSString *)bidder
                  externalPlacementId:(nullable NSString *)externalPlacementId
                              revenue:(nullable NSNumber *)revenue {
    self = [super init];
    if (self) {
        _placementName = placementName;
        _placementId = placementId;
        _bidder = bidder;
        _externalPlacementId = externalPlacementId;
        _revenue = revenue;
    }
    return self;
}

- (instancetype)init {
    return [self initWithPlacementName:nil
                           placementId:nil
                                bidder:nil
                   externalPlacementId:nil
                               revenue:nil];
}

+ (instancetype)adFromBid:(id)bid placementId:(NSString *)placementId {
    return [self adFromBid:bid placementId:placementId placementName:nil];
}

+ (instancetype)adFromBid:(id)bid placementId:(NSString *)placementId placementName:(NSString *)placementName {
    // Extract data from bid response using available properties
    NSString *resolvedPlacementName = nil;
    NSString *bidder = nil;
    NSString *externalPlacementId = nil;
    NSNumber *revenue = nil;
    
    if ([bid isKindOfClass:[CLXBidResponseBid class]]) {
        CLXBidResponseBid *bidResponse = (CLXBidResponseBid *)bid;
        
        // Use available bid response data
        externalPlacementId = bidResponse.adid; // Use adid as external placement ID
        revenue = @(bidResponse.price); // Use price as revenue
        
        // Try to get bidder from prebid meta (primary source) or adapter extras (fallback)
        if (bidResponse.ext && bidResponse.ext.prebid && bidResponse.ext.prebid.meta && bidResponse.ext.prebid.meta.adaptercode) {
            bidder = bidResponse.ext.prebid.meta.adaptercode;
        } else if (bidResponse.ext && bidResponse.ext.cloudx && bidResponse.ext.cloudx.adapterExtras) {
            bidder = bidResponse.ext.cloudx.adapterExtras[@"bidder"] ?: bidResponse.ext.cloudx.adapterExtras[@"adapter"];
        }
        
        // Use provided placement name if available, otherwise try adapter extras, then fall back to placement ID
        if (placementName && placementName.length > 0) {
            resolvedPlacementName = placementName;
        } else if (bidResponse.ext && bidResponse.ext.cloudx && bidResponse.ext.cloudx.adapterExtras) {
            resolvedPlacementName = bidResponse.ext.cloudx.adapterExtras[@"placementName"] ?: placementId;
        } else {
            resolvedPlacementName = placementId;
        }
    }

    // Only create CLXAd if we have valid bid data AND required fields
    if ([bid isKindOfClass:[CLXBidResponseBid class]] && bidder && bidder.length > 0 && revenue) {
        return [[self alloc] initWithPlacementName:resolvedPlacementName
                                       placementId:placementId
                                            bidder:bidder
                               externalPlacementId:externalPlacementId
                                           revenue:revenue];
    }
    
    // Return nil if we don't have valid bid data or required fields
    return nil;
}


@end
