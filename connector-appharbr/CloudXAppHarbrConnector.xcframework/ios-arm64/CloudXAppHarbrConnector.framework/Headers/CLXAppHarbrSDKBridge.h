/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAppHarbrSDKBridge.h
 * @brief CloudX-typed seam over the AppHarbr SDK so the connector and its tests
 *        never import AppHarbr directly.
 *
 * The connector depends on this protocol only. The production implementation
 * (CLXAppHarbrSDKProductionBridge) translates these CloudX-typed values to the
 * AppHarbr SDK's own types and is the single file that imports AppHarbr. Unit
 * tests inject a fake conforming to this protocol; the test target therefore
 * does not require the AppHarbr SDK.
 *
 * The enum raw values intentionally mirror the AppHarbr SDK's @c AHAdFormat,
 * @c AdSdk, and @c AHAdAnalysisResult enum cases so the production bridge can
 * convert with a plain cast at the boundary (one guard, strong types
 * everywhere else).
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** AppHarbr ad format, mirrored from @c AHAdFormat. */
typedef NS_ENUM(NSInteger, CLXAppHarbrAdFormat) {
    CLXAppHarbrAdFormatBanner = 1,
    CLXAppHarbrAdFormatInterstitial = 2,
    CLXAppHarbrAdFormatNative = 3,
    CLXAppHarbrAdFormatRewarded = 4,
    CLXAppHarbrAdFormatRewardedInterstitial = 5,
};

/**
 * AppHarbr ad-network SDK, mirrored case-by-case from @c AdSdk in the
 * AppHarbr swiftinterface (unchanged from 1.37.0 through 1.38.3) so the production
 * bridge can convert with a plain cast. @c cloudX identifies CloudX as both the
 * mediation layer (at init) and, for CloudX's own rendered inventory, the ad network;
 * it exists from AppHarbr 1.37.0, so no supported AppHarbr lacks it. The
 * superseded @c custom is kept for the generic slot. The
 * per-ad @c analyzeAd call must identify the real underlying network, or
 * AppHarbr rejects the ad with result 7 (unsupportedAdNetwork). @c none is the
 * sentinel for an unknown / unmapped network — AppHarbr rejects it with result
 * 7, which the connector fails open on (the correct outcome for a network
 * AppHarbr genuinely does not support). Only the cases our SDK produces or
 * the mapper needs are listed; the full AppHarbr enum has ~90 cases.
 */
typedef NS_ENUM(NSInteger, CLXAppHarbrAdSdk) {
    CLXAppHarbrAdSdkAdMob = 1,
    CLXAppHarbrAdSdkGAM = 2,
    CLXAppHarbrAdSdkFacebook = 4,
    CLXAppHarbrAdSdkChartboost = 10,
    CLXAppHarbrAdSdkIronSource = 17,
    CLXAppHarbrAdSdkUnity = 31,
    CLXAppHarbrAdSdkVungle = 34,
    CLXAppHarbrAdSdkMintegral = 37,
    CLXAppHarbrAdSdkBidMachine = 41,
    CLXAppHarbrAdSdkPubMatic = 57,
    CLXAppHarbrAdSdkRubicon = 58,
    CLXAppHarbrAdSdkVerve = 63,
    CLXAppHarbrAdSdkPangle = 24,
    CLXAppHarbrAdSdkInMobi = 16,
    CLXAppHarbrAdSdkMoloco = 89,
    CLXAppHarbrAdSdkMobileFuse = 53,
    CLXAppHarbrAdSdkYandex = 65,
    CLXAppHarbrAdSdkFyber = 13,
    CLXAppHarbrAdSdkCloudX = 100,
    CLXAppHarbrAdSdkCustom = 998,
    CLXAppHarbrAdSdkNone = 999,
};

/** AppHarbr analysis outcome, mirrored from @c AHAdAnalysisResult. */
typedef NS_ENUM(NSInteger, CLXAppHarbrAnalysisResult) {
    CLXAppHarbrAnalysisResultAdAnalyzedOnLoad = 0,
    CLXAppHarbrAnalysisResultBlockedBeforeDisplay = 1,
    CLXAppHarbrAnalysisResultBlockedAfterDisplay = 2,
    CLXAppHarbrAnalysisResultInvalidAdObject = 3,
    CLXAppHarbrAnalysisResultMissingAdNetworkUnitId = 4,
    CLXAppHarbrAnalysisResultVersionMismatch = 5,
    CLXAppHarbrAnalysisResultInternalError = 6,
    CLXAppHarbrAnalysisResultUnsupportedAdNetwork = 7,
    CLXAppHarbrAnalysisResultIncidentReport = 8,
    CLXAppHarbrAnalysisResultAnalyzeWillPerformOnDisplay = 9,
    CLXAppHarbrAnalysisResultTimeLimitWillExecute = 10,
    CLXAppHarbrAnalysisResultClickThresholdWillExecute = 11,
    CLXAppHarbrAnalysisResultUnsupportedMediation = 12,
    CLXAppHarbrAnalysisResultSdkNotInitialized = 13,
    CLXAppHarbrAnalysisResultInitializationInProgress = 14,
    CLXAppHarbrAnalysisResultPolicyUnavailable = 15,
};

/**
 * Delivered by the bridge when AppHarbr reports an analysis outcome. The bridge
 * translates AppHarbr's @c AHAdIncidentInfo.blockReasons into the @c blockReasons
 * array (empty for non-blocking results).
 */
typedef void (^CLXAppHarbrAnalysisCallback)(CLXAppHarbrAnalysisResult result,
                                           NSArray<NSString *> *blockReasons);

/**
 * Testability seam over @c AppHarbrAdQuality.shared. The connector talks to this
 * protocol; the production bridge forwards to the real SDK.
 */
@protocol CLXAppHarbrSDKBridge <NSObject>

/** YES when the AppHarbr SDK has been initialized by the publisher and is ready to analyze. */
- (BOOL)isReady;

/**
 * Begin ad analysis. The bridge retains its own delegate for the lifetime of the
 * analysis (AppHarbr may hold it weakly) and invokes @c callback for each analysis
 * outcome AppHarbr emits.
 */
- (void)analyzeAdWithAdObject:(NSObject *)adObject
                        format:(CLXAppHarbrAdFormat)format
                   adNetworkSdk:(CLXAppHarbrAdSdk)adNetworkSdk
                mediationUnitId:(NSString *)mediationUnitId
               adNetworkUnitId:(nullable NSString *)adNetworkUnitId
                       adapter:(nullable NSObject *)adapter
                   bidResponse:(nullable NSString *)bidResponse
          mediationCreativeId:(nullable NSString *)mediationCreativeId
          adNetworkCreativeId:(nullable NSString *)adNetworkCreativeId
                     extraData:(nullable NSDictionary<NSString *, id> *)extraData
                     callback:(CLXAppHarbrAnalysisCallback)callback;

/** Forward AppHarbr display lifecycle. */
- (void)didDisplayAd:(NSObject *)adObject;
/** Forward AppHarbr click lifecycle. */
- (void)didClickAd:(NSObject *)adObject;
/** Forward AppHarbr will-close lifecycle. */
- (void)willCloseAd:(NSObject *)adObject;
/** Stop monitoring the ad; releases any per-ad state the bridge holds for it. */
- (void)removeAd:(NSObject *)adObject;

@end

NS_ASSUME_NONNULL_END
