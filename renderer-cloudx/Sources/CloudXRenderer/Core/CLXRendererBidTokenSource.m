//
//  CLXRendererBidTokenSource.m
//  CloudXRenderer
//
//  Renderer bid token source implementation
//

#import "CLXRendererBidTokenSource.h"
#import <CloudXCore/CLXLogger.h>

@implementation CLXRendererBidTokenSource

+ (instancetype)createInstance {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererBidTokenSource"];
    [logger debug:@"Creating new CLXRendererBidTokenSource instance"];
    return [[CLXRendererBidTokenSource alloc] init];
}

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *,NSString *> * _Nullable, NSError * _Nullable))completion {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXRendererBidTokenSource"];
    [logger debug:@"Getting Renderer token"];
    
    // For Renderer, we typically don't need special tokens, but we can provide
    // a basic identifier for tracking purposes
    NSString *rendererId = [[NSUUID UUID] UUIDString];
    NSDictionary *token = @{@"renderer_id": rendererId};
    
    [logger verbose:[NSString stringWithFormat:@"Generated Renderer token: %@", token]];
    completion(token, nil);
}

@end 