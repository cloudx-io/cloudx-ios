/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXBidResponse.h>

@interface CLXAd ()

// Primary storage (new property names)
@property (nonatomic, readwrite, nullable) NSString *adUnitName;
@property (nonatomic, readwrite, nullable) NSString *adUnitId;
@property (nonatomic, readwrite, nullable) NSString *networkName;
@property (nonatomic, readwrite, nullable) NSString *networkPlacement;
@property (nonatomic, readwrite, nullable) NSNumber *revenue;

@end

@implementation CLXAd

#pragma mark - Deprecated Property Accessors (forward to new names)

- (NSString *)placementName {
    return self.adUnitName;
}

- (NSString *)placementId {
    return self.adUnitId;
}

- (NSString *)bidder {
    return self.networkName;
}

- (NSString *)externalPlacementId {
    return self.networkPlacement;
}

#pragma mark - Initializers

- (instancetype)initWithAdUnitName:(nullable NSString *)adUnitName
                          adUnitId:(nullable NSString *)adUnitId
                       networkName:(nullable NSString *)networkName
                  networkPlacement:(nullable NSString *)networkPlacement
                           revenue:(nullable NSNumber *)revenue {
    self = [super init];
    if (self) {
        _adUnitName = adUnitName;
        _adUnitId = adUnitId;
        _networkName = networkName;
        _networkPlacement = networkPlacement;
        _revenue = revenue;
    }
    return self;
}

// Deprecated initializer - forwards to new initializer
- (instancetype)initWithPlacementName:(nullable NSString *)placementName
                          placementId:(nullable NSString *)placementId
                               bidder:(nullable NSString *)bidder
                  externalPlacementId:(nullable NSString *)externalPlacementId
                              revenue:(nullable NSNumber *)revenue {
    return [self initWithAdUnitName:placementName
                           adUnitId:placementId
                        networkName:bidder
                   networkPlacement:externalPlacementId
                            revenue:revenue];
}

- (instancetype)init {
    return [self initWithAdUnitName:nil
                           adUnitId:nil
                        networkName:nil
                   networkPlacement:nil
                            revenue:nil];
}

+ (instancetype)adFromBid:(id)bid placementId:(NSString *)placementId {
    return [self adFromBid:bid placementId:placementId placementName:nil];
}

+ (instancetype)adFromBid:(id)bid placementId:(NSString *)placementId placementName:(NSString *)placementName {
    // Extract data from bid response using available properties
    NSString *resolvedAdUnitName = nil;
    NSString *networkName = nil;
    NSString *networkPlacement = nil;
    NSNumber *revenue = nil;
    
    if ([bid isKindOfClass:[CLXBidResponseBid class]]) {
        CLXBidResponseBid *bidResponse = (CLXBidResponseBid *)bid;
        
        // Revenue from ext.cloudx.revenue
        if (bidResponse.ext && bidResponse.ext.cloudx) {
            revenue = @(bidResponse.ext.cloudx.revenue);
        }
        
        // Extract network placement with fallback chain
        // Priority: adid (OpenRTB standard) > adapter_extras placement_id > crid > bid ID
        // Note: Each network uses different terminology:
        // - Meta/Vungle/InMobi: placement_id
        // - Mintegral: ad_unit_id (server sends both placement_id and ad_unit_id)
        networkPlacement = bidResponse.adid;
        if (!networkPlacement || networkPlacement.length == 0) {
            if (bidResponse.ext && bidResponse.ext.cloudx && bidResponse.ext.cloudx.adapterExtras) {
                networkPlacement = bidResponse.ext.cloudx.adapterExtras[@"placement_id"];
            }
        }
        if (!networkPlacement || networkPlacement.length == 0) {
            networkPlacement = bidResponse.crid ?: bidResponse.id;
        }
        
        // Try to get network name from prebid meta (primary source) or adapter extras (fallback)
        if (bidResponse.ext && bidResponse.ext.prebid && bidResponse.ext.prebid.meta && bidResponse.ext.prebid.meta.adaptercode) {
            networkName = bidResponse.ext.prebid.meta.adaptercode;
        } else if (bidResponse.ext && bidResponse.ext.cloudx && bidResponse.ext.cloudx.adapterExtras) {
            networkName = bidResponse.ext.cloudx.adapterExtras[@"bidder"] ?: bidResponse.ext.cloudx.adapterExtras[@"adapter"];
        }
        
        // Use provided placement name if available, otherwise try adapter extras, then fall back to placement ID
        if (placementName && placementName.length > 0) {
            resolvedAdUnitName = placementName;
        } else if (bidResponse.ext && bidResponse.ext.cloudx && bidResponse.ext.cloudx.adapterExtras) {
            resolvedAdUnitName = bidResponse.ext.cloudx.adapterExtras[@"placementName"] ?: placementId;
        } else {
            resolvedAdUnitName = placementId;
        }
    }

    // Only create CLXAd if we have valid bid data AND required fields
    if ([bid isKindOfClass:[CLXBidResponseBid class]] && networkName && networkName.length > 0 && revenue) {
        return [[self alloc] initWithAdUnitName:resolvedAdUnitName
                                       adUnitId:placementId
                                    networkName:networkName
                               networkPlacement:networkPlacement
                                        revenue:revenue];
    }
    
    // Return nil if we don't have valid bid data or required fields
    return nil;
}


@end
