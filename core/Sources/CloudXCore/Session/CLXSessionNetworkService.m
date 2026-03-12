/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXSessionNetworkService.h>
#import <CloudXCore/CLXBaseNetworkService.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>

@interface CLXSessionNetworkService ()
@property (nonatomic, strong) CLXBaseNetworkService *baseNetworkService;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXSessionNetworkService

- (instancetype)initWithBaseNetworkService:(CLXBaseNetworkService *)baseNetworkService {
    self = [super init];
    if (self) {
        _baseNetworkService = baseNetworkService;
        _logger = [[CLXLogger alloc] initWithCategory:@"SessionNetworkService"];
    }
    return self;
}

- (void)sendWithAppKey:(NSString *)appKey
               payload:(NSDictionary<NSString *, id> *)payload
            completion:(nullable void (^)(BOOL success, NSError * _Nullable error))completion {

    NSError *jsonError;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:&jsonError];

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
                                               timeout:0
                                            maxRetries:1
                                                 delay:1.0
                                            completion:^(id _Nullable response, NSError * _Nullable error, BOOL isKillSwitchEnabled) {
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Session event failed: %@", error.localizedDescription]];
            if (completion) {
                completion(NO, error);
            }
            return;
        }

        [self.logger debug:@"Session event sent successfully"];
        if (completion) {
            completion(YES, nil);
        }
    }];
}

@end
