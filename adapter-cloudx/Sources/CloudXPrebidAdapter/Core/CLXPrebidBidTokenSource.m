//
//  CLXPrebidBidTokenSource.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 bid token source implementation
//

#import "CLXPrebidBidTokenSource.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXPrebidBidTokenSource

+ (instancetype)createInstance {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidBidTokenSource"];
    [logger debug:@"Creating new CLXPrebidBidTokenSource instance"];
    return [[CLXPrebidBidTokenSource alloc] init];
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *,NSString *> * _Nullable, NSError * _Nullable))completion {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidBidTokenSource"];
    [logger debug:@"Getting Prebid token"];
    
    // For Prebid, we typically don't need special tokens, but we can provide
    // a basic identifier for tracking purposes
    NSString *prebidId = [[NSUUID UUID] UUIDString];
    NSDictionary *token = @{@"prebid_id": prebidId};
    
    [logger debug:[NSString stringWithFormat:@"Generated Prebid token: %@", token]];
    completion(token, nil);
}

@end 