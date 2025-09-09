//
//  CloudXPrebidAdapter.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 compliant rendering adapter for CloudX mediation
//  Focuses purely on ad rendering - all bid logic handled by CloudX Core SDK
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

//! Project version number for CloudXPrebidAdapter.
FOUNDATION_EXPORT double CloudXPrebidAdapterVersionNumber;

//! Project version string for CloudXPrebidAdapter.
FOUNDATION_EXPORT const unsigned char CloudXPrebidAdapterVersionString[];

// Core Rendering Engine  
#import "CLXPrebidWebView.h"
#import "CLXPrebidError.h"

// Advanced MRAID and Performance
#import "CLXMRAIDManager.h"
#import "CLXViewabilityTracker.h"
#import "CLXPerformanceManager.h"
#import "CLXVASTParser.h"

// Ad Unit Factories
#import "CLXPrebidBannerFactory.h"
#import "CLXPrebidInterstitialFactory.h"
#import "CLXPrebidNativeFactory.h"
#import "CLXPrebidRewardedFactory.h"

// Initializer
#import "CLXPrebidInitializer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudX Prebid 3.0 Rendering Adapter
 * 
 * This adapter focuses purely on rendering prebid ad markup received from the 
 * CloudX Core SDK. All bid requests, auction logic, and server communication
 * are handled by the core SDK's CLXBidNetworkService.
 *
 * Key Features:
 * - Complete MRAID 3.0 implementation with resize/expand/collapse
 * - Advanced viewability tracking with IAB compliance  
 * - High-performance caching and memory management
 * - VAST 4.0 video ad support with comprehensive tracking
 * - Background resource preloading and optimization
 * - Native impression tracking with view hierarchy analysis
 * - Support for banner, interstitial, native, and rewarded formats
 * - Transparent rendering without additional mediation fees
 */
@interface CloudXPrebidAdapter : NSObject

/**
 * Get current adapter version (Prebid 3.0 compliant)
 * @return Version string in format "3.0.x"
 */
+ (NSString *)version;

/**
 * Get adapter network name for core SDK registration
 * @return Network identifier used by core SDK
 */
+ (NSString *)networkName;

@end

NS_ASSUME_NONNULL_END