#import "CLXMintegralBannerFactory.h"
#import "CLXMintegralBanner.h"
#import "CLXMintegralIDExtractor.h"
#import <CloudXCore/CLXError.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBannerType.h>

@interface CLXMintegralBannerFactory ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMintegralBannerFactory

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMintegralBannerFactory"];
    }
    return self;
}

+ (instancetype)createInstance {
    return [[CLXMintegralBannerFactory alloc] init];
}

- (NSString *)network {
    return @"mintegral";
}

- (nullable id<CLXAdapterBanner>)createWithViewController:(UIViewController *)viewController
                                                     type:(CLXBannerType)type
                                                     adId:(NSString *)adId
                                                    bidId:(NSString *)bidId
                                                      adm:(NSString *)adm
                                          hasClosedButton:(BOOL)hasClosedButton
                                                   extras:(NSDictionary<NSString *, NSString *> *)extras
                                              adUnitName:(NSString *)adUnitName
                                                 delegate:(id<CLXAdapterBannerDelegate>)delegate {
    
    [self.logger debug:[NSString stringWithFormat:@"[BannerFactory] Creating banner - Ad Unit: %@ (%@), bidId:'%@', type:%ld",
                        adUnitName ?: @"(unknown)", adId ?: @"(nil)", bidId ?: @"(nil)", (long)type]];
    
    // Extract IDs using shared utility
    CLXMintegralIDResult *ids = [CLXMintegralIDExtractor extractIDsFromExtras:extras
                                                                         adId:adId
                                                                   bidIdParam:bidId
                                                                       logger:self.logger];
    
    // Log validation warning if unitID is missing (validation deferred to load())
    if (!ids.unitID.length) {
        [self.logger error:@"[BannerFactory] Missing unit_id - validation will be deferred to load()"];
    }
    
    // Convert banner type to size
    CGSize bannerSize;
    switch (type) {
        case CLXBannerTypeMREC:
            bannerSize = CGSizeMake(300, 250);
            break;
        case CLXBannerTypeW320H50:
        default:
            bannerSize = CGSizeMake(320, 50);
            break;
    }
    
    // Use adm as bidPayload (nil-safe: messaging nil returns 0)
    NSString *bidPayload = adm.length > 0 ? adm : nil;
    
    [self.logger debug:[NSString stringWithFormat:@"[BannerFactory] Creating Mintegral banner - Ad Unit: %@, placementID:%@, unitID:%@, size:%.0fx%.0f, hasBidPayload:%@",
                        adUnitName ?: @"(unknown)", ids.placementID, ids.unitID, bannerSize.width, bannerSize.height, bidPayload ? @"YES" : @"NO"]];
    
    // Always create and return adapter (even with invalid parameters)
    // Validation errors will be reported in load() via delegate callback
    CLXMintegralBanner *banner = [[CLXMintegralBanner alloc] initWithBidPayload:bidPayload
                                                                    placementID:ids.placementID
                                                                  adUnitName:adUnitName
                                                                         unitID:ids.unitID
                                                                           size:bannerSize
                                                                          bidID:ids.bidID ?: @""
                                                                       delegate:delegate];
    
    [self.logger debug:@"[BannerFactory] Mintegral banner adapter created successfully"];
    return banner;
}

@end
