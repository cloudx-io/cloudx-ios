//
//  CLXMetaNativeFactory.m
//  CloudXMetaAdapter
//
//  Created by CLX on 2024-02-14.
//

// Conditional import for internal headers to support both SPM and CocoaPods/Xcode.
// SPM requires angle brackets with module name, CocoaPods/Xcode supports quotes.
#if __has_include(<CloudXMetaAdapter/CLXMetaNativeFactory.h>)
#import <CloudXMetaAdapter/CLXMetaNativeFactory.h>
#else
#import "CLXMetaNativeFactory.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaNative.h>)
#import <CloudXMetaAdapter/CLXMetaNative.h>
#else
#import "CLXMetaNative.h"
#endif

#if __has_include(<CloudXMetaAdapter/CLXMetaBaseFactory.h>)
#import <CloudXMetaAdapter/CLXMetaBaseFactory.h>
#else
#import "CLXMetaBaseFactory.h"
#endif

#import <CloudXCore/CLXLogger.h>

@interface CLXMetaNativeFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetaNativeFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaNativeFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    CLXMetaNativeFactory *instance = [[CLXMetaNativeFactory alloc] init];
    return instance;
}

- (nullable id<CLXAdapterNative>)createWithViewController:(UIViewController *)viewController
                                                        type:(CLXNativeTemplate)type
                                                        adId:(NSString *)adId
                                                       bidId:(NSString *)bidId
                                                         adm:(NSString *)adm
                                                      extras:(NSDictionary<NSString *, NSString *> *)extras
                                                    delegate:(id<CLXAdapterNativeDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"✅ [CLXMetaNativeFactory] Creating native for placement: %@ | bidPayload: %@", adId, adm ? @"YES" : @"NO"]];

    // Use shared base factory method to resolve Meta placement ID
    NSString *metaPlacementID = [CLXMetaBaseFactory resolveMetaPlacementID:extras 
                                                              fallbackAdId:adId 
                                                                    logger:self.logger];

    // Validate placement ID
    if (!metaPlacementID || metaPlacementID.length == 0) {
        [self.logger error:@"Cannot create native adapter - placement ID is nil or empty"];
        return nil;
    }

    CLXMetaNative *native = [[CLXMetaNative alloc] initWithBidPayload:adm
                                                          placementID:metaPlacementID
                                                                bidID:bidId
                                                                 type:type
                                                       viewController:viewController
                                                             delegate:delegate];
    
    return native;
}

@end 
