//
//  CloudXPrebidBannerFactory.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 banner factory implementation for CloudX Prebid Adapter
//  
//  This class provides factory methods for creating banner ad instances including:
//  - Banner instance creation with validation
//  - Parameter validation and error handling
//  - Ad markup processing and preview logging
//  - Delegate setup and configuration
//  - Performance tracking and metrics
//  - Comprehensive logging for debugging
//

#import "CLXPrebidBannerFactory.h"
#import "CLXPrebidBanner.h"
#import <CloudXCore/CLXLogger.h>

/**
 * CLXPrebidBannerFactory - Factory for creating banner ad instances
 * 
 * Provides factory methods to create and configure banner ad instances
 * with proper validation, error handling, and logging.
 */
@implementation CLXPrebidBannerFactory

/**
 * Create a new instance of CLXPrebidBannerFactory
 * 
 * Factory method for creating banner factory instances.
 * Used by the adapter resolution system to instantiate banner factories.
 * 
 * @return New CLXPrebidBannerFactory instance
 */
+ (instancetype)createInstance {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"PrebidBannerFactory"];
    [logger debug:@"🔧 [PrebidBannerFactory] createInstance called"];
    CLXPrebidBannerFactory *instance = [[CLXPrebidBannerFactory alloc] init];
    [logger info:[NSString stringWithFormat:@"✅ [PrebidBannerFactory] Instance created: %@", instance]];
    return instance;
}

/**
 * Create a banner ad instance with the specified parameters
 * 
 * Validates input parameters and creates a properly configured banner instance.
 * Performs comprehensive validation and logging for debugging purposes.
 * 
 * @param viewController View controller for modal presentations
 * @param type Banner type (standard, MREC, etc.)
 * @param adId Unique identifier for the ad
 * @param bidId Unique identifier for the bid
 * @param adm Ad markup string (HTML/JavaScript content)
 * @param hasClosedButton Whether to show close button for expandable ads
 * @param extras Additional configuration parameters
 * @param delegate Banner delegate for event callbacks
 * @return Configured CLXPrebidBanner instance or nil if creation fails
 */
- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                      type:(CLXBannerType)type
                                                      adId:(NSString *)adId
                                                     bidId:(NSString *)bidId
                                                       adm:(NSString *)adm
                                              hasClosedButton:(BOOL)hasClosedButton
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                                   delegate:(id<CLXAdapterBannerDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXPrebidBannerFactory"];
    [logger info:@"🏭 [FACTORY] CloudXPrebidBannerFactory create method called"];
    [logger debug:[NSString stringWithFormat:@"📊 [FACTORY] Parameters:"]];
    [logger debug:[NSString stringWithFormat:@"  📍 ViewController: %@ (%@)", viewController ? @"Present" : @"nil", viewController ? NSStringFromClass([viewController class]) : @"N/A"]];
    [logger debug:[NSString stringWithFormat:@"  📍 Banner type: %ld", (long)type]];
    [logger debug:[NSString stringWithFormat:@"  📍 Ad ID: %@", adId ?: @"nil"]];
    [logger debug:[NSString stringWithFormat:@"  📍 Bid ID: %@", bidId ?: @"nil"]];
    [logger debug:[NSString stringWithFormat:@"  📍 Ad markup length: %lu characters", (unsigned long)(adm ? adm.length : 0)]];
    [logger debug:[NSString stringWithFormat:@"  📍 Has close button: %@", hasClosedButton ? @"YES" : @"NO"]];
    [logger debug:[NSString stringWithFormat:@"  📍 Extras: %@", extras ?: @"{}"]];
    [logger debug:[NSString stringWithFormat:@"  📍 Delegate: %@", delegate ? @"Present" : @"nil"]];
    
    // Validate required parameters
    if (!viewController) {
        [logger error:@"❌ [FACTORY] Cannot create banner - viewController is nil"];
        return nil;
    }
    
    if (!adm || adm.length == 0) {
        [logger error:@"❌ [FACTORY] Cannot create banner - ad markup is empty or nil"];
        return nil;
    }
    
    if (!delegate) {
        [logger info:@"⚠️ [FACTORY] Creating banner without delegate - callbacks will not work"];
    }
    
    [logger info:@"✅ [FACTORY] Validation passed, creating CloudXPrebidBanner instance..."];
    
    // Log ad markup preview for debugging
    if (adm.length > 0) {
        [logger debug:[NSString stringWithFormat:@"📊 [FACTORY] Ad markup preview: %@...", 
                      [adm substringToIndex:MIN(150, adm.length)]]];
    }
    
    // Create banner instance with validated parameters
    CLXPrebidBanner *banner = [[CLXPrebidBanner alloc] initWithAdm:adm
                                                                        hasClosedButton:hasClosedButton
                                                                                   type:type
                                                                          viewController:viewController
                                                                               delegate:delegate];
    
    if (banner) {
        [logger info:[NSString stringWithFormat:@"✅ [FACTORY] CloudXPrebidBanner created successfully: %p", banner]];
        [logger debug:[NSString stringWithFormat:@"📊 [FACTORY] Banner class: %@", NSStringFromClass([banner class])]];
        [logger debug:[NSString stringWithFormat:@"📊 [FACTORY] Conforms to CLXAdapterBanner: %@", [banner conformsToProtocol:@protocol(CLXAdapterBanner)] ? @"YES" : @"NO"]];
        [logger debug:[NSString stringWithFormat:@"📊 [FACTORY] Banner SDK version: %@", [banner sdkVersion]]];
        [logger info:@"🎯 [FACTORY] Banner creation completed successfully"];
        return banner;
    } else {
        [logger error:@"❌ [FACTORY] Failed to create CloudXPrebidBanner instance"];
        return nil;
    }
}

@end 