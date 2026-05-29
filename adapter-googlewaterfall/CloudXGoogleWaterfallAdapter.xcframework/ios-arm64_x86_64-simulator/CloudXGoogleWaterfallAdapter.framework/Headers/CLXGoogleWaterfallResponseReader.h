#import <Foundation/Foundation.h>

@class GADResponseInfo;

NS_ASSUME_NONNULL_BEGIN

/// Probe labels + winner metadata read from an AdMob fill's response info.
/// Mirrors Android AdapterResponseReader.ExtractedFill.
@interface CLXGoogleWaterfallExtractedFill : NSObject
@property (nonatomic, copy, readonly) NSArray<NSString *> *probesTriggered;
@property (nonatomic, copy, readonly, nullable) NSString *winnerSourceName;
@property (nonatomic, copy, readonly, nullable) NSString *winnerInstanceName;
@property (nonatomic, copy, readonly, nullable) NSString *mediationGroupName;

- (instancetype)initWithProbesTriggered:(NSArray<NSString *> *)probesTriggered
                       winnerSourceName:(nullable NSString *)winnerSourceName
                     winnerInstanceName:(nullable NSString *)winnerInstanceName
                     mediationGroupName:(nullable NSString *)mediationGroupName NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

/// Reads probe-trigger labels + winner from Google's GADResponseInfo for an
/// AdMob fill. Forwards raw `Probe_F*` labels as Google emits them; the SSP
/// parses proxyPrice = min(label tier) server-side. No regex on device.
@interface CLXGoogleWaterfallResponseReader : NSObject

/// Extract from a GMA response info. Nil-safe → empty fill.
+ (CLXGoogleWaterfallExtractedFill *)extractFromResponseInfo:(nullable GADResponseInfo *)info;

/// Pure extraction over already-read primitives, for testing without a real
/// GADResponseInfo. `instanceNames` are the per-network adSourceInstanceName
/// values in waterfall order.
+ (CLXGoogleWaterfallExtractedFill *)extractFromInstanceNames:(nullable NSArray<NSString *> *)instanceNames
                                            winnerSourceName:(nullable NSString *)winnerSourceName
                                          winnerInstanceName:(nullable NSString *)winnerInstanceName
                                          mediationGroupName:(nullable NSString *)mediationGroupName;

@end

NS_ASSUME_NONNULL_END
