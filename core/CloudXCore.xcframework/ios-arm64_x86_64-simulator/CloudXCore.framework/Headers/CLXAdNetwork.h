/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Typed adapter network identifier — single source of truth for known ad networks.
typedef NSString *CLXAdNetwork NS_STRING_ENUM;

extern CLXAdNetwork const CLXAdNetworkTestBidder;
extern CLXAdNetwork const CLXAdNetworkGoogleAdManager;
extern CLXAdNetwork const CLXAdNetworkMeta;
extern CLXAdNetwork const CLXAdNetworkMintegral;
extern CLXAdNetwork const CLXAdNetworkCloudX;
extern CLXAdNetwork const CLXAdNetworkCloudXRenderer;
extern CLXAdNetwork const CLXAdNetworkVungle;
extern CLXAdNetwork const CLXAdNetworkInMobi;
extern CLXAdNetwork const CLXAdNetworkUnityAds;
extern CLXAdNetwork const CLXAdNetworkMagnite;

/// All known ad networks.
extern NSArray<CLXAdNetwork> *CLXAllAdNetworks(void);

/// Maps a network identifier to its ObjC class name prefix (e.g. CLXAdNetworkInMobi → @"InMobi").
extern NSString *CLXAdNetworkClassName(CLXAdNetwork network);

/// Maps a network identifier to its adapter framework namespace
/// (e.g. CLXAdNetworkMeta → @"CLXMetaAdapter", CLXAdNetworkCloudXRenderer → @"CloudXRenderer").
extern NSString *_Nullable CLXAdNetworkAdapterNamespace(CLXAdNetwork network);

NS_ASSUME_NONNULL_END
