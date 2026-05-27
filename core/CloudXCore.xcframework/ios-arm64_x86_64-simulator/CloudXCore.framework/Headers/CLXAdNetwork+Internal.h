/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdNetwork+Internal.h
 * @brief Internal adapter registry keys and lookup helpers.
 * @discussion These symbols are referenced only by CloudXCore's own translation
 *             units (factory resolver, metadata resolver, privacy forwarder).
 *             They are intentionally hidden in the shipped binary so adapter
 *             authors cannot link against them. The `CLXAdNetwork` typedef
 *             itself remains in the public header because public API uses it
 *             as a typed identifier.
 */

#import <CloudXCore/CLXAdNetwork.h>

NS_ASSUME_NONNULL_BEGIN

extern CLXAdNetwork const CLXAdNetworkBidMachine;
extern CLXAdNetwork const CLXAdNetworkChartboost;
extern CLXAdNetwork const CLXAdNetworkCloudX;
extern CLXAdNetwork const CLXAdNetworkCloudXRenderer;
extern CLXAdNetwork const CLXAdNetworkDigitalTurbine;
extern CLXAdNetwork const CLXAdNetworkGoogleAdManager;
extern CLXAdNetwork const CLXAdNetworkGoogleWaterfall;
extern CLXAdNetwork const CLXAdNetworkInMobi;
extern CLXAdNetwork const CLXAdNetworkLoopMe;
extern CLXAdNetwork const CLXAdNetworkMagnite;
extern CLXAdNetwork const CLXAdNetworkMeta;
extern CLXAdNetwork const CLXAdNetworkMintegral;
extern CLXAdNetwork const CLXAdNetworkMobileFuse;
extern CLXAdNetwork const CLXAdNetworkMoloco;
extern CLXAdNetwork const CLXAdNetworkPangle;
extern CLXAdNetwork const CLXAdNetworkPubMatic;
extern CLXAdNetwork const CLXAdNetworkTestBidder;
extern CLXAdNetwork const CLXAdNetworkUnityAds;
extern CLXAdNetwork const CLXAdNetworkVerve;
extern CLXAdNetwork const CLXAdNetworkVungle;
extern CLXAdNetwork const CLXAdNetworkYandex;

/// All known ad networks.
extern NSArray<CLXAdNetwork> *CLXAllAdNetworks(void);

/// Maps a network identifier to its ObjC class name prefix (e.g. CLXAdNetworkInMobi → @"InMobi").
extern NSString *CLXAdNetworkClassName(CLXAdNetwork network);

/// Maps a network identifier to its adapter framework namespace
/// (e.g. CLXAdNetworkMeta → @"CLXMetaAdapter", CLXAdNetworkCloudXRenderer → @"CloudXRenderer").
extern NSString *_Nullable CLXAdNetworkAdapterNamespace(CLXAdNetwork network);

NS_ASSUME_NONNULL_END
