#import "CLXGeoApi.h"
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/URLSession+CLX.h>

@interface CLXGeoApi ()
@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXGeoApi

- (instancetype)initWithUrl:(NSString *)url {
    return [self initWithUrl:url session:[NSURLSession cloudxSession] userDefaults:[NSUserDefaults standardUserDefaults]];
}

- (instancetype)initWithUrl:(NSString *)url session:(NSURLSession *)session userDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (self) {
        _url = url;
        _session = session;
        _userDefaults = userDefaults;
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXGeoApi"];
    }
    return self;
}

- (void)fetchGeoHeaders:(void(^)(NSDictionary<NSString *, NSString *> * _Nullable headers, NSError * _Nullable error))completion {
    NSURL *urlObj = [NSURL URLWithString:self.url];
    if (!urlObj) {
        [self.logger error:[NSString stringWithFormat:@"Invalid URL: %@", self.url]];
        NSError *error = [NSError errorWithDomain:@"CLXGeoApi"
                                             code:-1
                                         userInfo:@{NSLocalizedDescriptionKey: @"Invalid URL"}];
        completion(nil, error);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 5.0;

    [self.logger debug:[NSString stringWithFormat:@"Fetching geo headers from: %@", self.url]];

    NSDate *startTime = [NSDate date];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger latencyMs = (NSInteger)([NSDate.date timeIntervalSinceDate:startTime] * 1000);
        [self.userDefaults setInteger:latencyMs forKey:kCLXCoreGeoLatencyMsKey];
        [self.logger debug:[NSString stringWithFormat:@"Geo API latency: %ldms", (long)latencyMs]];

        if (error) {
            [self.logger warn:[NSString stringWithFormat:@"Geo header fetch failed: %@", error.localizedDescription]];
            completion(nil, error);
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (httpResponse.statusCode / 100 != 2) {
            [self.logger warn:[NSString stringWithFormat:@"Geo header fetch returned HTTP %ld", (long)httpResponse.statusCode]];
            NSError *statusError = [NSError errorWithDomain:@"CLXGeoApi"
                                                       code:httpResponse.statusCode
                                                   userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unexpected HTTP status: %ld", (long)httpResponse.statusCode]}];
            completion(nil, statusError);
            return;
        }

        NSDictionary<NSString *, NSString *> *headers = httpResponse.allHeaderFields;

        [self.logger debug:[NSString stringWithFormat:@"Successfully fetched %lu geo headers", (unsigned long)headers.count]];
        completion(headers, nil);
    }];

    [task resume];
}

@end
