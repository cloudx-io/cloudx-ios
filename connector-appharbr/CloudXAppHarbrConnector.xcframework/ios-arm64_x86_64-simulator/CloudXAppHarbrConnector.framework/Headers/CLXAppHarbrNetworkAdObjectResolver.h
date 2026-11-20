/*
 * Copyright (c) 2026 CloudX. All rights reserved.
 */

/**
 * @file CLXAppHarbrNetworkAdObjectResolver.h
 * @brief Finds the ad network SDK's own ad object behind a CloudX ad, without the adapter's help.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Finds the network SDK's ad object that AppHarbr inspects, starting from the CloudX objects
 * core submits.
 *
 * @discussion AppHarbr validates the ad network's own ad class and rejects CloudX objects.
 * Every adapter must hold the network's ad object to show it, so this class finds it on the
 * adapter instance. Every adapter version, already published or not,
 * is covered without an adapter release.
 *
 * Safety rules. Any doubt returns nil, and the caller keeps the CloudX object, which is the
 * fail-open behavior a missing hook already has:
 * - Reads only stored (@c V), strong or copied (@c & / @c C), object-typed properties, from their
 *   backing instance variables. It never calls a getter, so no adapter code runs, and never
 *   reads @c weak or unretained properties.
 * - Runs only on the main thread, where adapters write these properties; elsewhere it returns nil.
 * - Walks only CloudX classes (adapters, and one level into CloudX helper objects they own). It
 *   never enumerates UIKit or network SDK classes.
 * - Never calls a method on a network SDK object. Classes are matched by name, so a network SDK
 *   that renames or removes a class stops matching instead of failing.
 * - The only call into a network SDK class is a shared-instance accessor, for networks whose
 *   bid-loaded rewarded ad lives in a process-wide manager. It is guarded by
 *   @c respondsToSelector:, and used only when the bid carries ad markup.
 */
@interface CLXAppHarbrNetworkAdObjectResolver : NSObject

/**
 * @brief The resolver with the built-in network tables.
 * @return A shared, stateless resolver.
 */
+ (instancetype)defaultResolver;

/**
 * @brief Creates a resolver with explicit network tables.
 * @param preferredClassNames CloudX network name to network SDK class names, most preferred
 *        first. Consulted when an adapter holds more than one network object.
 * @param biddingRewardedSharedManagerClassNames CloudX network name to network SDK classes
 *        whose @c sharedInstance holds a bid-loaded rewarded ad. Consulted only for rewarded
 *        ads whose bid carries ad markup, when the adapter holds no network object.
 * @return A resolver using those tables.
 */
- (instancetype)initWithPreferredClassNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)preferredClassNames
     biddingRewardedSharedManagerClassNames:(NSDictionary<NSString *, NSArray<NSString *> *> *)biddingRewardedSharedManagerClassNames
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * @brief Finds the network SDK's ad object for one ad.
 * @param adapter The CloudX adapter that loaded the ad (@c CLXAdQualityRequest.adapter).
 * @param adNetwork The CloudX network name (@c CLXAdQualityRequest.adNetwork).
 * @param rewarded YES for rewarded ads, the only format a shared manager is consulted for.
 * @param bidPayload The bid's raw JSON (@c CLXAdQualityRequest.bidPayload). A shared manager
 *        is consulted only when it carries ad markup (@c adm or @c ext.signaldata).
 * @return The network SDK's ad object, or nil when it cannot be identified unambiguously or
 *         when called off the main thread.
 */
- (nullable NSObject *)networkAdObjectForAdapter:(nullable NSObject *)adapter
                                       adNetwork:(nullable NSString *)adNetwork
                                        rewarded:(BOOL)rewarded
                                      bidPayload:(nullable NSDictionary *)bidPayload;

/**
 * @brief Whether an object's class is a CloudX class (prefix @c CLX or @c CloudX).
 * @param object Any object, or nil.
 * @return YES for CloudX objects. Core submits a CloudX object when the adapter does not hand
 *         over the network's own ad object itself.
 */
+ (BOOL)isCloudXObject:(nullable NSObject *)object;

@end

NS_ASSUME_NONNULL_END
