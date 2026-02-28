/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXIlrdNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXIlrdNetworkService ()
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXIlrdNetworkService

- (instancetype)initWithBaseURL:(NSString *)baseURL urlSession:(NSURLSession *)urlSession {
    CLXBaseNetworkService *baseService = [[CLXBaseNetworkService alloc] initWithBaseURL:baseURL urlSession:urlSession];
    return [self initWithBaseNetworkService:baseService];
}

- (instancetype)initWithBaseNetworkService:(CLXBaseNetworkService *)baseNetworkService {
    self = [super init];
    if (self) {
        _baseNetworkService = baseNetworkService;
        _logger = [[CLXLogger alloc] initWithCategory:@"IlrdNetworkService"];
    }
    return self;
}

- (void)sendWithAppKey:(NSString *)appKey
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(void (^)(BOOL success, NSError * _Nullable error))completion {

    NSError *jsonError;
    NSData *jsonData = nil;

    @try {
        jsonData = [NSJSONSerialization dataWithJSONObject:payload
                                                  options:0
                                                    error:&jsonError];
    } @catch (NSException *exception) {
        jsonError = [NSError errorWithDomain:@"CLXIlrdNetworkService"
                                        code:1001
                                    userInfo:@{
                                        NSLocalizedDescriptionKey: [NSString stringWithFormat:@"JSON serialization exception: %@", exception.reason],
                                    }];
    }

    if (jsonError || !jsonData) {
        [self.logger error:[NSString stringWithFormat:@"JSON serialization failed: %@", jsonError.localizedDescription]];
        if (completion) {
            completion(NO, jsonError);
        }
        return;
    }

    NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
    headers[@"Authorization"] = [NSString stringWithFormat:@"Bearer %@", appKey];
    headers[@"Content-Type"] = @"application/json";

    [self.baseNetworkService executeRequestWithEndpoint:@""
                                         urlParameters:nil
                                           requestBody:jsonData
                                               headers:headers
                                               timeout:0 /* Use session default (30s) */
                                            maxRetries:0
                                                 delay:0
                                            completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"ILRD send failed: %@", error.localizedDescription]];
            if (completion) {
                completion(NO, error);
            }
            return;
        }

        if (completion) {
            completion(YES, nil);
        }
    }];
}

@end
