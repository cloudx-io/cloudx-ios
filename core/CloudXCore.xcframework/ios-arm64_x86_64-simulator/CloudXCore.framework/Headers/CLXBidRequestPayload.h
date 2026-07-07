#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLegacyTrackerSnapshot;

/**
 * Carrier passed from `CLXBidSignals` to `CLXBidNetworkService`. Holds the
 * v2 SignalPayload JSON body and the matching `CLXLegacyTrackerSnapshot` of the
 * request's `;`-positional tracker fields. The snapshot has no client-side
 * reader now; it is retained for the server-side pubimp_replacement bridge.
 */
@interface CLXBidRequestPayload : NSObject

/** The v2 SignalPayload JSON body sent as the bid request. */
@property (nonatomic, copy, readonly) NSString *bodyJSON;
/** Snapshot of the `;`-positional tracker fields; consumed only by the server-side pubimp_replacement bridge. */
@property (nonatomic, strong, readonly) CLXLegacyTrackerSnapshot *legacySnapshot;

- (instancetype)initWithBodyJSON:(NSString *)bodyJSON
                  legacySnapshot:(CLXLegacyTrackerSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
