#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLegacyTrackerSnapshot;

/**
 * Carrier passed from `CLXBidSignals` to `CLXBidNetworkService`. Holds the
 * v2 SignalPayload JSON body and the matching `CLXLegacyTrackerSnapshot`
 * that the auction coordinator registers with `CLXTrackingFieldResolver`
 * for legacy `;`-positional tracker resolution.
 */
@interface CLXBidRequestPayload : NSObject

@property (nonatomic, copy, readonly) NSString *bodyJSON;
@property (nonatomic, strong, readonly) CLXLegacyTrackerSnapshot *legacySnapshot;

- (instancetype)initWithBodyJSON:(NSString *)bodyJSON
                  legacySnapshot:(CLXLegacyTrackerSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
