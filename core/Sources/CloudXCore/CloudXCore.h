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

//! Project version number for CloudXCore.
FOUNDATION_EXPORT double CloudXCoreVersionNumber;

//! Project version string for CloudXCore.
FOUNDATION_EXPORT const unsigned char CloudXCoreVersionString[];

// =============================================================================
// MARK: - PUBLIC API
// =============================================================================

// Core SDK
#import <CloudXCore/CLXVersion.h>
#import <CloudXCore/CloudXCoreAPI.h>
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXAdType.h>

// Configuration
#import <CloudXCore/CLXInitializationConfiguration.h>
#import <CloudXCore/CLXSettings.h>
#import <CloudXCore/CLXPrivacyConsent.h>
#import <CloudXCore/CLXConsentProvider.h>
#import <CloudXCore/CLXSDKConfig.h>
#import <CloudXCore/CLXSDKConfigAdUnit.h>
#import <CloudXCore/CLXBiddingConfig.h>

// Ad Base
#import <CloudXCore/CLXAd.h>
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
#import <CloudXCore/CLXAdapterBanner.h>
#import <CloudXCore/CLXAdapterBannerFactory.h>
#import <CloudXCore/CLXAdapterRewarded.h>
#import <CloudXCore/CLXAdapterRewardedFactory.h>
#import <CloudXCore/CLXAdapterInterstitial.h>
#import <CloudXCore/CLXAdapterInterstitialFactory.h>
#import <CloudXCore/CLXAdNetworkInitializer.h>
#import <CloudXCore/CLXAdNetworkFactories.h>
#import <CloudXCore/CLXBidTokenSource.h>
#import <CloudXCore/CLXAdapterFactoryResolver.h>
#import <CloudXCore/CLXAdapterLoader.h>

// Adapter Models
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXBidderConfig.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXFullscreenAd.h>

// Adapter Services
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXAdEventReporter.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>

// Utilities
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXORTBConstants.h>
#import <CloudXCore/CLXPlacementValidator.h>

// =============================================================================
// MARK: - INTERNAL (transitively imported for module compatibility)
// =============================================================================
// Internal headers are imported via CloudXCoreInternal.h
// These are NOT part of the public API and may change without notice.

#import <CloudXCore/CloudXCoreInternal.h>

NS_ASSUME_NONNULL_BEGIN
NS_ASSUME_NONNULL_END
