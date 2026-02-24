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
@property (nonatomic, readwrite) CLXAdFormat adFormat;
@property (nonatomic, readwrite, nullable) NSString *placement;

@end

@implementation CLXAd

#pragma mark - Initializers

- (instancetype)initWithAdUnitName:(nullable NSString *)adUnitName
                          adUnitId:(nullable NSString *)adUnitId
                       networkName:(nullable NSString *)networkName
                  networkPlacement:(nullable NSString *)networkPlacement
                           revenue:(nullable NSNumber *)revenue
                          adFormat:(CLXAdFormat)adFormat
                         placement:(nullable NSString *)placement {
    self = [super init];
    if (self) {
        _adUnitName = adUnitName;
        _adUnitId = adUnitId;
        _networkName = networkName;
        _networkPlacement = networkPlacement;
        _revenue = revenue;
        _adFormat = adFormat;
        _placement = placement;
    }
    return self;
}

- (instancetype)init {
    return [self initWithAdUnitName:nil
                           adUnitId:nil
                        networkName:nil
                   networkPlacement:nil
                            revenue:nil
                           adFormat:CLXAdFormatBanner
                          placement:nil];
}

+ (instancetype)adFromBid:(id)bid
                 adUnitId:(NSString *)adUnitId
                 adFormat:(CLXAdFormat)adFormat
                placement:(nullable NSString *)placement {
    return [self adFromBid:bid adUnitId:adUnitId adUnitName:nil adFormat:adFormat placement:placement];
}

+ (instancetype)adFromBid:(id)bid
                 adUnitId:(NSString *)adUnitId
               adUnitName:(NSString *)adUnitName
                 adFormat:(CLXAdFormat)adFormat
                placement:(nullable NSString *)placement {
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
        
        networkName = [CLXBidResponse resolveAdapterCodeFromExt:bidResponse.ext];
        
        // Use provided ad unit name if available, otherwise try adapter extras, then fall back to ad unit ID
        if (adUnitName && adUnitName.length > 0) {
            resolvedAdUnitName = adUnitName;
        } else if (bidResponse.ext && bidResponse.ext.cloudx && bidResponse.ext.cloudx.adapterExtras) {
            resolvedAdUnitName = bidResponse.ext.cloudx.adapterExtras[@"adUnitName"] ?: @"";
        } else {
            resolvedAdUnitName = @"";
        }
    }

    // Only create CLXAd if we have valid bid data AND required fields
    if ([bid isKindOfClass:[CLXBidResponseBid class]] && networkName && networkName.length > 0 && revenue) {
        return [[self alloc] initWithAdUnitName:resolvedAdUnitName
                                       adUnitId:adUnitId
                                    networkName:networkName
                               networkPlacement:networkPlacement
                                        revenue:revenue
                                       adFormat:adFormat
                                      placement:placement];
    }
    
    // Return nil if we don't have valid bid data or required fields
    return nil;
}


@end
