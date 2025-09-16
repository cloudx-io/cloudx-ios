#import <CloudXCore/CLXAdEventReporter.h>
#import <CloudXCore/CLXAdReportingNetworkService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/URLSession+CLX.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdDelegate.h>
#import <CloudXCore/CLXEnvironmentConfig.h>

@interface CLXAdEventReporter ()
@property (nonatomic, strong) CLXAdReportingNetworkService *reportNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXAdEventReporter

- (instancetype)initWithEndpoint:(NSString *)endpoint {
    self = [super init];
    if (self) {
        CLXEnvironmentConfig *env = [CLXEnvironmentConfig shared];
        NSString *endpointString = endpoint.length > 0 ? endpoint : env.eventTrackingEndpointURL;
        NSURL *endpointURL = [NSURL URLWithString:endpointString];
        NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"event"];
        _reportNetworkService = [[CLXAdReportingNetworkService alloc] initWithBaseURL:endpointURL urlSession:urlSession];
        _logger = [[CLXLogger alloc] initWithCategory:@"LiveAdEventReporter"];
    }
    return self;
}

- (void)impressionWithBidID:(NSString *)bidID {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSError *error;
        [strongSelf.reportNetworkService trackImpressionWithBidID:bidID error:&error];
        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Failed to track impression: %@", error.localizedDescription]];
        }
    });
}

- (void)winWithBidID:(NSString *)bidID {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSError *error;
        [strongSelf.reportNetworkService trackWinWithBidID:bidID error:&error];
        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Failed to track win: %@", error.localizedDescription]];
        }
    });
}


- (void)fireNurlForRevenueWithPrice:(double)price nUrl:(nullable NSString *)nUrl completion:(void(^)(BOOL success, CLXAd * _Nullable ad))completion {
    // Clean separation: reporting service only handles network requests, caller handles callbacks
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            if (completion) {
                completion(NO, nil);
            }
            return;
        }
        
        [strongSelf.reportNetworkService trackNUrlWithPrice:price nUrl:nUrl completion:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                [strongSelf.logger error:[NSString stringWithFormat:@"Failed to fire NURL: %@", error.localizedDescription]];
            }
            
            if (success) {
                [strongSelf.logger debug:[NSString stringWithFormat:@"💰 NURL fired successfully, price=%.2f", price]];
            } else {
                [strongSelf.logger error:[NSString stringWithFormat:@"❌ Failed to fire NURL for revenue callback: %@", error.localizedDescription ?: @"Unknown error"]];
            }
            
            // Call completion - caller will handle threading for revenue callback
            if (completion) {
                completion(success, nil); // Ad will be created by the caller
            }
        }];
    });
}

- (void)fireLurlWithUrl:(nullable NSString *)lUrl reason:(NSInteger)reason {
    if (!lUrl || lUrl.length == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        // Replace macros like ${AUCTION_LOSS} and ${AUCTION_PRICE} (same logic as CLXLossReporter)
        NSString *resolvedLurl = [lUrl stringByReplacingOccurrencesOfString:@"${AUCTION_LOSS}" withString:[NSString stringWithFormat:@"%ld", (long)reason]];
        NSString *finalLurl = [resolvedLurl stringByReplacingOccurrencesOfString:@"${AUCTION_PRICE}" withString:@""]; // Price is not typically included in loss URLs
        
        [strongSelf.reportNetworkService trackLUrlWithLUrl:finalLurl];
    });
}

- (void)geoTrackingWithURLString:(NSString *)fullURL
                          extras:(NSDictionary<NSString *, NSString *> *)extras {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSError *error;
        [strongSelf.reportNetworkService geoHeadersWithURLString:fullURL extras:extras];
        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Failed to track geo: %@", error.localizedDescription]];
        }
    });
}

- (void)rillTrackingWithActionString:(NSString *)actionString campaignId:(NSString *)campaignId encodedString:(NSString *)encodedString {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSError *error;
        [strongSelf.reportNetworkService rillTrackingWithActionString:actionString campaignId:(NSString *)campaignId encodedString:encodedString error:&error];
        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Failed to track rill: %@", error.localizedDescription]];
        }
    });
}

- (void)metricsTrackingWithActionString:(NSString *)actionString {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSError *error;
        [strongSelf.reportNetworkService metricsTrackingWithActionString:actionString error:&error];
        if (error) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Failed to track rill: %@", error.localizedDescription]];
        }
    });
}

@end 
