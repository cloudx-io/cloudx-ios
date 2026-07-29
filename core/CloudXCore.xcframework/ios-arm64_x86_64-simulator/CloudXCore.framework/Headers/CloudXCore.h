//
//  CloudXCore.h
//  CloudXCore SDK
//
//  The main umbrella header for CloudXCore.
//  Import this header to access all public CloudX SDK functionality.
//
//  For adapter developers: Additional headers are available via direct import:
//    #import <CloudXCore/CLXSpecificHeader.h>
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <CloudXCore/CLXExport.h>

// =============================================================================
// MARK: - PUBLIC API
// =============================================================================

// Core SDK
#import <CloudXCore/CLXVersion.h>
#import <CloudXCore/CloudXCoreAPI.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXAdType.h>
#import <CloudXCore/CLXArbiterBid.h>
#import <CloudXCore/CLXArbiterConfiguration.h>
#import <CloudXCore/CLXArbiterPlatform.h>
#import <CloudXCore/CLXArbiterPrecision.h>
#import <CloudXCore/CLXArbiterResult.h>

// Configuration
#import <CloudXCore/CLXInitializationConfiguration.h>
#import <CloudXCore/CLXRevenueData.h>
#import <CloudXCore/CLXRevenuePlatform.h>
#import <CloudXCore/CLXRevenuePrecision.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyConsent.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSDKRaceSafetyConfig.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>

// Ad Base
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdFormat.h>
#import <CloudXCore/CLXAdDelegate.h>
#import <CloudXCore/CLXFullscreenAdDelegate.h>
#import <CloudXCore/CLXAdRevenueDelegate.h>
#import <CloudXCore/CLXDestroyable.h>

// Banner
#import <CloudXCore/CLXBanner.h>
#import <CloudXCore/CLXBannerDelegate.h>
#import <CloudXCore/CLXBannerAdView.h>
#import <CloudXCore/CLXBannerType.h>

// Interstitial
#import <CloudXCore/CLXInterstitial.h>
#import <CloudXCore/CLXInterstitialDelegate.h>

// Rewarded
#import <CloudXCore/CLXRewarded.h>
#import <CloudXCore/CLXRewardedDelegate.h>
#import <CloudXCore/CLXReward.h>

// App Open
#import <CloudXCore/CLXAppOpen.h>
#import <CloudXCore/CLXAppOpenDelegate.h>

// Native
#import <CloudXCore/CLXNativeAd.h>
#import <CloudXCore/CLXNativeAdImage.h>
#import <CloudXCore/CLXNativeAdBuilder.h>
#import <CloudXCore/CLXNativeAdView.h>
#import <CloudXCore/CLXNativeAdViewBinder.h>
#import <CloudXCore/CLXNativeAdLoader.h>
#import <CloudXCore/CLXNativeAdDelegate.h>
#import <CloudXCore/CLXNativeTemplate.h>
#import <CloudXCore/CLXNative.h>
#import <CloudXCore/CLXNativeDelegate.h>

// Debug UI
#import <CloudXCore/CLXDebugOverlayManager.h>
#import <CloudXCore/CLXDebugButton.h>
#import <CloudXCore/CLXDebugLogViewController.h>
#import <CloudXCore/CLXDebugErrorView.h>
#import <CloudXCore/CLXDebugClickFeedback.h>

// =============================================================================
// MARK: - ADAPTER DEVELOPMENT
// =============================================================================

// Adapter Protocols
#import <CloudXCore/CLXAdNetwork.h>
#import <CloudXCore/CLXAdapterAdView.h>
#import <CloudXCore/CLXAdapterAdViewFactory.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdapterNative.h>
#import <CloudXCore/CLXAdapterNativeFactory.h>
#import <CloudXCore/CLXAdapterInitializer.h>
#import <CloudXCore/CLXAdapterBidderSignalsProvider.h>
#import <CloudXCore/CLXAdapterMetadataProvider.h>
#import <CloudXCore/CLXAdapterLogger.h>
#import <CloudXCore/CLXAdapterLoadParams.h>
#import <CloudXCore/CLXAdapterShowParams.h>
#import <CloudXCore/CLXAdapterParams.h>
#import <CloudXCore/CLXAdapterInitializationParams.h>
#import <CloudXCore/CLXAdapterBidderSignalsParams.h>
#import <CloudXCore/CLXAdapterInterstitialParams.h>
#import <CloudXCore/CLXAdViewAdapterParams.h>
#import <CloudXCore/CLXAdapterNativeParams.h>
#import <CloudXCore/CLXAdapterRewardedParams.h>
#import <CloudXCore/CLXAdapterAdFormat.h>
#import <CloudXCore/CLXAdapterNativeVideoOptions.h>
#import <CloudXCore/CLXAdapterUtils.h>


// Adapter Models
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXBidResponseExtModels.h>
#import <CloudXCore/CLXBidRoute.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXFullscreenAd.h>

// Adapter Services
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXPrivacyService.h>

// Manual Privacy Controls
#import <CloudXCore/CLXManualPrivacyState.h>
#import <CloudXCore/CLXAdapterPrivacyHandler.h>
#import <CloudXCore/CLXAdapterPrivacyParams.h>
#import <CloudXCore/CLXPrivacyConsentResolver.h>

// Utilities
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXORTBConstants.h>
#import <CloudXCore/CLXAdUnitValidator.h>

// Additional exported SDK headers
#import <CloudXCore/CLXAppLifecycleMonitor.h>
#import <CloudXCore/CLXAuctionBidManager.h>
#import <CloudXCore/CLXAuctionResult.h>
#import <CloudXCore/CLXBackgroundTimer.h>
#import <CloudXCore/CLXBaseEvent.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidNetworkService.h>
#import <CloudXCore/CLXBidRequestPayload.h>
#import <CloudXCore/CLXBidSignals.h>
#import <CloudXCore/CLXDIContainer.h>
#import <CloudXCore/CLXErrorReporter.h>
#import <CloudXCore/CLXEventType.h>
#import <CloudXCore/CLXGeoInfo.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXInitService.h>
#import <CloudXCore/CLXKeyValueState.h>
#import <CloudXCore/CLXLegacyTrackerSnapshot.h>
#import <CloudXCore/CLXLiveInitService.h>
#import <CloudXCore/CLXLogEntry.h>
#import <CloudXCore/CLXLogStore.h>
#import <CloudXCore/CLXMetricsConfig.h>
#import <CloudXCore/CLXMetricsEvent.h>
#import <CloudXCore/CLXMetricsType.h>
#import <CloudXCore/CLXPrivacyBlock.h>
#import <CloudXCore/CLXPublisherNative.h>
#import <CloudXCore/CLXReachabilityService.h>
#import <CloudXCore/CLXSDKBlock.h>
#import <CloudXCore/CLXSDKBlockProvider.h>
#import <CloudXCore/CLXSDKInitNetworkService.h>
#import <CloudXCore/CLXSKAdNetworkService.h>
#import <CloudXCore/CLXSQLiteDatabase.h>
#import <CloudXCore/CLXSessionMetrics.h>
#import <CloudXCore/CLXSessionMetricsTracker.h>
#import <CloudXCore/CLXUIApplicationProxy.h>
#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXUserAgentProvider.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <CloudXCore/URLSession+CLX.h>
