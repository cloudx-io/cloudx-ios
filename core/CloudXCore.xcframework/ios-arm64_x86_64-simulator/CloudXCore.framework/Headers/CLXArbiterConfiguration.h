#import <Foundation/Foundation.h>
#import <CloudXCore/CLXArbiterBid.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief Builder for constructing CLXArbiterConfiguration instances.
 */
CLX_PUBLIC
@interface CLXArbiterConfigurationBuilder : NSObject

/**
 * @brief Bid candidates to compare.
 */
@property (nonatomic, copy) NSArray<CLXArbiterBid *> *bids;

@end

/**
 * @brief Configuration for running the CloudX arbiter.
 *
 * Create an instance with the bid candidates that should be submitted to the arbiter:
 * @code
 * CLXArbiterConfiguration *config =
 *     [CLXArbiterConfiguration configurationWithBids:@[cloudXBid, levelPlayBid]];
 * @endcode
 */
CLX_PUBLIC
@interface CLXArbiterConfiguration : NSObject

/**
 * @brief Bid candidates to compare.
 */
@property (nonatomic, copy, readonly) NSArray<CLXArbiterBid *> *bids;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 * @brief Creates a configuration with bid candidates.
 *
 * @param bids Bid candidates to compare.
 * @return A new configuration instance.
 */
+ (instancetype)configurationWithBids:(NSArray<CLXArbiterBid *> *)bids;

/**
 * @brief Creates a configuration with bid candidates and a builder block.
 *
 * @param bids Bid candidates to compare.
 * @param builderBlock Block to configure additional options via the builder.
 * @return A new configuration instance.
 */
+ (instancetype)configurationWithBids:(NSArray<CLXArbiterBid *> *)bids
                         builderBlock:(nullable void (^)(CLXArbiterConfigurationBuilder *builder))builderBlock
    NS_SWIFT_NAME(configuration(bids:builderBlock:));

@end

NS_ASSUME_NONNULL_END
