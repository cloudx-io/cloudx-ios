//
//  CloudXRenderer.h
//  CloudXRenderer
//
//  CloudX Renderer for in-house and third-party demand sources
//  Focuses purely on ad rendering - all bid logic handled by CloudX Core SDK
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

//! Project version number for CloudXRenderer.
FOUNDATION_EXPORT double CloudXRendererVersionNumber;

//! Project version string for CloudXRenderer.
FOUNDATION_EXPORT const unsigned char CloudXRendererVersionString[];

// Core Rendering Engine  
#import "CLXRendererWebView.h"
#import "CLXRendererError.h"

// Advanced MRAID and Performance
#import "CLXMRAIDManager.h"
#import "CLXViewabilityTracker.h"
#import "CLXPerformanceManager.h"
#import "CLXVASTParser.h"

// Ad Unit Factories
#import "CLXRendererBannerFactory.h"
#import "CLXRendererInterstitialFactory.h"
#import "CLXRendererNativeFactory.h"
#import "CLXRendererRewardedFactory.h"

// Initializer
#import "CLXRendererInitializer.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * CloudX Renderer
 * 
 * This renderer focuses purely on rendering ad markup received from the 
 * CloudX Core SDK or third-party demand sources. All bid requests, auction logic, 
 * and server communication are handled by the core SDK's CLXBidNetworkService.
 *
 * Key Features:
 * - Complete MRAID 3.0 implementation with resize/expand/collapse
 * - Advanced viewability tracking with IAB compliance  
 * - High-performance caching and memory management
 * - VAST 4.0 video ad support with comprehensive tracking
 * - Background resource preloading and optimization
 * - Native impression tracking with view hierarchy analysis
 * - Support for banner, interstitial, native, and rewarded formats
 * - Transparent rendering without additional fees
 */
@interface CloudXRenderer : NSObject

/**
 * Get current renderer version
 * @return Version string in format "1.x.x"
 */
+ (NSString *)version;

/**
 * Get renderer network name for core SDK registration
 * @return Network identifier used by core SDK
 */
+ (NSString *)networkName;

@end

NS_ASSUME_NONNULL_END