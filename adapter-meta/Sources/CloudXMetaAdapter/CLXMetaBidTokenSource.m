//
//  CLXMetaBidTokenSource.m
//  CloudXMetaAdapter
//

#if __has_include(<CloudXMetaAdapter/CLXMetaBidTokenSource.h>)
#import <CloudXMetaAdapter/CLXMetaBidTokenSource.h>
#else
#import "CLXMetaBidTokenSource.h"
#endif

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXError.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

@interface CLXMetaBidTokenSource ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXMetaBidTokenSource

+ (instancetype)sharedInstance {
    static CLXMetaBidTokenSource *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXMetaBidTokenSource alloc] init];
    });
    return sharedInstance;
}

+ (instancetype)createInstance {
    return [self sharedInstance];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CLXMetaBidTokenSource"];
    }
    return self;
}

#pragma mark - CLXBidTokenSource

- (void)getTokenWithCompletion:(void (^)(NSDictionary<NSString *, NSString *> * _Nullable token, NSError * _Nullable error))completion {
    [self.logger debug:@"Getting Meta bidder token"];

    // IMPORTANT: Must use background queue, NOT main queue.
    // [FBAdSettings bidderToken] is a blocking call that acquires an internal lock.
    // When another SDK concurrently holds the lock, this can take several seconds.
    // Calling on main thread causes UI freeze/ANR.
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        if (!strongSelf) {
            if (completion) {
                NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInternalError
                                             description:@"Bid token source was deallocated"];
                completion(nil, error);
            }
            return;
        }

        @try {
            NSString *bidderToken = [FBAdSettings bidderToken];
            [strongSelf.logger debug:[NSString stringWithFormat:@"Meta bidder token: %@",
                                     bidderToken ? @"[RECEIVED]" : @"[NIL]"]];

            NSDictionary<NSString *, NSString *> *tokenDict = nil;
            if (bidderToken && bidderToken.length > 0) {
                tokenDict = @{@"bidder_token": bidderToken};
            }

            if (completion) {
                completion(tokenDict, nil);
            }

        } @catch (NSException *exception) {
            [strongSelf.logger error:[NSString stringWithFormat:@"Exception getting token: %@", exception.reason]];

            NSError *error = [CLXError errorWithCode:CLXErrorCodeAdapterInternalError
                                         description:exception.reason ?: @"Unknown exception"];

            if (completion) {
                completion(nil, error);
            }
        }
    });
}

@end
