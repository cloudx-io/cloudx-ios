#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

/// Starts the Google Mobile Ads SDK and the prefetch worker for the provisioned
/// `googleWaterfallPlacements`. Banner + MREC only.
@interface CLXGoogleWaterfallInitializer : CLXAdNetworkInitializer

@property (nonatomic, copy, readonly) NSString *network;

+ (BOOL)isInitialized;
+ (NSString *)sdkVersion;

- (void)initializeWithConfig:(nullable CLXBidderConfig *)config
                    testMode:(BOOL)testMode
                  completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
