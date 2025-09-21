#import <CloudXCore/CLXAdEventReporter.h>
#import <CloudXCore/CLXAdReportingNetworkService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/URLSession+CLX.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdDelegate.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>

@interface CLXAdEventReporter ()
@property (nonatomic, strong) CLXAdReportingNetworkService *reportNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXAdEventReporter

- (instancetype)initWithEndpoint:(NSString *)endpoint {
    self = [super init];
    if (self) {
        // Use provided endpoint or fallback to stored event tracking URL from SDK response
        NSString *fallbackURL = [[NSUserDefaults standardUserDefaults] stringForKey:kCLXCoreMetricsUrlKey] ?: @"";
        NSString *endpointString = endpoint.length > 0 ? endpoint : fallbackURL;
        NSURL *endpointURL = [NSURL URLWithString:endpointString];
        NSURLSession *urlSession = [NSURLSession cloudxSessionWithIdentifier:@"event"];
        _reportNetworkService = [[CLXAdReportingNetworkService alloc] initWithBaseURL:endpointURL urlSession:urlSession];
        _logger = [[CLXLogger alloc] initWithCategory:@"LiveAdEventReporter"];
    }
    return self;
}



// Legacy fireNurlForRevenueWithPrice and fireLurlWithUrl methods removed
// Use CLXWinLossTracker for server-side win/loss tracking instead

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
            [strongSelf.logger error:[NSString stringWithFormat:@"Failed to track metrics: %@", error.localizedDescription]];
        }
    });
}

@end 
