//
//  CLXRendererBannerFactory.m
//  CloudXRenderer
//
//  Renderer banner factory implementation for CloudX Renderer
//  
//  This class provides factory methods for creating banner ad instances including:
//  - Banner instance creation with validation
//  - Parameter validation and error handling
//  - Ad markup processing and preview logging
//  - Delegate setup and configuration
//  - Performance tracking and metrics
//  - Comprehensive logging for debugging
//

#import "CLXRendererBannerFactory.h"
#import "CLXRendererBanner.h"
#import <CloudXCore/CLXLogger.h>

/**
 * CLXRendererBannerFactory - Factory for creating banner ad instances
 * 
 * Provides factory methods to create and configure banner ad instances
 * with proper validation, error handling, and logging.
 */
@implementation CLXRendererBannerFactory

/**
 * Create a new instance of CLXRendererBannerFactory
 * 
 * Factory method for creating banner factory instances.
 * Used by the adapter resolution system to instantiate banner factories.
 * 
 * @return New CLXRendererBannerFactory instance
 */
+ (instancetype)createInstance {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"RendererBannerFactory"];
    [logger debug:@"createInstance called"];
    CLXRendererBannerFactory *instance = [[CLXRendererBannerFactory alloc] init];
    [logger info:[NSString stringWithFormat:@"Instance created: %@", instance]];
    return instance;
}

/**
 * Create a banner ad instance with the specified parameters
 * 
 * Validates input parameters and creates a properly configured banner instance.
 * Performs comprehensive validation and logging for debugging purposes.
 * 
 * @param type Banner type (standard, MREC, etc.)
 * @param adId Unique identifier for the ad
 * @param bidId Unique identifier for the bid
 * @param adm Ad markup string (HTML/JavaScript content)
 * @param hasClosedButton Whether to show close button for expandable ads
 * @param extras Additional configuration parameters
 * @param adUnitName CloudX ad unit name for error messaging (may be nil)
 * @param delegate Banner delegate for event callbacks
 * @return Configured CLXRendererBanner instance or nil if creation fails
 */
- (nullable id<CLXAdapterBanner>)createWithType:(CLXBannerType)type
                                                      adId:(NSString *)adId
                                                     bidId:(NSString *)bidId
                                                       adm:(NSString *)adm
                                              hasClosedButton:(BOOL)hasClosedButton
                                                     extras:(NSDictionary<NSString *, NSString *> *)extras
                                                adUnitName:(nullable NSString *)adUnitName
                                                   delegate:(id<CLXAdapterBannerDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CloudXRendererBannerFactory"];
    [logger debug:[NSString stringWithFormat:@"Creating banner - Ad Unit: %@ (%@), BidID: %@, Type: %ld, Markup: %lu chars, CloseBtn: %@", 
                  adUnitName ?: @"(unknown)", adId, bidId, (long)type, (unsigned long)(adm ? adm.length : 0), hasClosedButton ? @"YES" : @"NO"]];
    
    if (!adm || adm.length == 0) {
        [logger error:@"Cannot create banner - ad markup is empty or nil"];
        return nil;
    }
    
    if (!delegate) {
        [logger warn:@"Creating banner without delegate"];
    }
    
    [logger debug:@"Validation passed, creating CloudXRendererBanner instance..."];
    
    // Log ad markup preview for debugging
    if (adm.length > 0) {
        [logger debug:[NSString stringWithFormat:@"Ad markup preview: %@...", 
                      [adm substringToIndex:MIN(150, adm.length)]]];
    }
    
    CLXRendererBanner *banner = [[CLXRendererBanner alloc] initWithAdm:adm
                                                                        hasClosedButton:hasClosedButton
                                                                                   type:type
                                                                               delegate:delegate];
    
    if (banner) {
        [logger debug:[NSString stringWithFormat:@"CloudXRendererBanner created successfully: %p", banner]];
        return banner;
    } else {
        [logger error:@"Failed to create CloudXRendererBanner instance"];
        return nil;
    }
}

@end 