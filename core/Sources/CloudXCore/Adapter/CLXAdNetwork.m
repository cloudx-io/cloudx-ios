/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXAdNetwork.h>

CLXAdNetwork const CLXAdNetworkTestBidder      = @"testbidder";
CLXAdNetwork const CLXAdNetworkGoogleAdManager = @"googleAdManager";
CLXAdNetwork const CLXAdNetworkMeta            = @"meta";
CLXAdNetwork const CLXAdNetworkMintegral       = @"mintegral";
CLXAdNetwork const CLXAdNetworkCloudX          = @"cloudx";
CLXAdNetwork const CLXAdNetworkCloudXRenderer  = @"cloudXRenderer";
CLXAdNetwork const CLXAdNetworkVungle          = @"vungle";
CLXAdNetwork const CLXAdNetworkInMobi          = @"inmobi";
CLXAdNetwork const CLXAdNetworkUnityAds         = @"unityads";
CLXAdNetwork const CLXAdNetworkMoloco          = @"moloco";

NSArray<CLXAdNetwork> *CLXAllAdNetworks(void) {
    static NSArray<CLXAdNetwork> *all;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        all = @[
            CLXAdNetworkTestBidder,
            CLXAdNetworkGoogleAdManager,
            CLXAdNetworkMeta,
            CLXAdNetworkMintegral,
            CLXAdNetworkCloudX,
            CLXAdNetworkCloudXRenderer,
            CLXAdNetworkVungle,
            CLXAdNetworkInMobi,
            CLXAdNetworkUnityAds,
            CLXAdNetworkMoloco,
        ];
    });
    return all;
}

NSString *CLXAdNetworkClassName(CLXAdNetwork network) {
    static NSDictionary<CLXAdNetwork, NSString *> *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            CLXAdNetworkTestBidder:      @"Renderer",
            CLXAdNetworkGoogleAdManager: @"AdManager",
            CLXAdNetworkMeta:            @"Meta",
            CLXAdNetworkMintegral:       @"Mintegral",
            CLXAdNetworkCloudX:          @"DSP",
            CLXAdNetworkCloudXRenderer:  @"Renderer",
            CLXAdNetworkVungle:          @"Vungle",
            CLXAdNetworkInMobi:          @"InMobi",
            CLXAdNetworkUnityAds:         @"UnityAds",
            CLXAdNetworkMoloco:          @"Moloco",
        };
    });
    return map[network] ?: @"Renderer";
}

NSString *_Nullable CLXAdNetworkAdapterNamespace(CLXAdNetwork network) {
    NSString *className = CLXAdNetworkClassName(network);
    if ([className isEqualToString:@"Renderer"]) {
        return @"CloudXRenderer";
    }
    return [NSString stringWithFormat:@"CLX%@Adapter", className];
}
