//
// CLXSdkConfiguration.h
// CloudXCore
//
// Configuration data returned after successful SDK initialization.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXExport.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @brief One CloudX ad unit's configuration for this session.
 *
 * Read from the configuration the SDK initialized with. It does not change when the SDK later applies
 * a newer configuration, and it does not depend on whether a mediator initialized or an ad is available.
 */
CLX_PUBLIC
@interface CLXAdUnitConfiguration : NSObject

/**
 * @brief YES when the ad unit has an Orchestrator load plan, so its loads run the plan's mediators.
 *        NO for an ordinary CloudX ad unit.
 */
@property (nonatomic, assign, readonly, getter=isOrchestratorEnabled) BOOL orchestratorEnabled;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 * @brief Configuration data returned after successful SDK initialization.
 *
 * This object is passed to the initialization completion handler upon success. Every completion of
 * the same session receives the same snapshot.
 */
CLX_PUBLIC
@interface CLXSdkConfiguration : NSObject

/**
 * @brief Immutable session snapshot keyed by CloudX ad unit ID.
 *
 * Includes ordinary and orchestrated ad units. An absent key means the ad unit is unknown to this
 * configuration. Never nil.
 */
@property (nonatomic, copy, readonly) NSDictionary<NSString *, CLXAdUnitConfiguration *> *adUnitConfigurations;

@end

NS_ASSUME_NONNULL_END
