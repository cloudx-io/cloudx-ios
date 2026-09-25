#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSDKConfig.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXMediatorConfiguration : NSObject
@property (nonatomic, copy, readonly) NSString *mediatorName;
@property (nonatomic, copy, readonly, getter=mediatorInitData) NSDictionary<NSString *, id> *initData;
/// Server-driven hard deadline for this mediator's initialization callback, in
/// milliseconds. Nil means no SDK-owned deadline (parity with Android).
@property (nonatomic, strong, readonly, nullable) NSNumber *hardInitTimeoutMs;
- (instancetype)initWithMediatorName:(NSString *)mediatorName
                            initData:(NSDictionary<NSString *, id> *)initData
                    hardInitTimeoutMs:(nullable NSNumber *)hardInitTimeoutMs NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface CLXMediatorAttempt : NSObject
@property (nonatomic, copy, readonly) NSString *mediatorName;
@property (nonatomic, copy, readonly) NSString *mediatorDisplayName;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *adUnitData;
@property (nonatomic, strong, readonly, nullable) NSNumber *timeoutMs;
- (instancetype)initWithMediatorName:(NSString *)mediatorName
                 mediatorDisplayName:(NSString *)mediatorDisplayName
                          adUnitData:(NSDictionary<NSString *, id> *)adUnitData
                           timeoutMs:(nullable NSNumber *)timeoutMs NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface CLXPostBidAttempt : NSObject
@property (nonatomic, copy, readonly) NSString *mediatorName;
@property (nonatomic, copy, readonly) NSString *mediatorDisplayName;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, id> *adUnitData;
@property (nonatomic, strong, readonly, nullable) NSNumber *timeoutMs;
- (instancetype)initWithMediatorName:(NSString *)mediatorName
                 mediatorDisplayName:(NSString *)mediatorDisplayName
                          adUnitData:(NSDictionary<NSString *, id> *)adUnitData
                           timeoutMs:(nullable NSNumber *)timeoutMs NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface CLXLoadGroup : NSObject
@property (nonatomic, copy, readonly) NSArray<CLXMediatorAttempt *> *mediators;
- (instancetype)initWithMediators:(NSArray<CLXMediatorAttempt *> *)mediators NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface CLXLoadPlan : NSObject
@property (nonatomic, copy, readonly) NSArray<CLXLoadGroup *> *groups;
@property (nonatomic, strong, readonly, nullable) CLXPostBidAttempt *postBid;
- (instancetype)initWithGroups:(NSArray<CLXLoadGroup *> *)groups
                       postBid:(nullable CLXPostBidAttempt *)postBid NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface CLXOrchestratorConfiguration : NSObject
@property (nonatomic, copy, readonly) NSArray<CLXMediatorConfiguration *> *mediatorCatalog;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, CLXMediatorConfiguration *> *mediatorsByName;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, CLXLoadPlan *> *loadPlansByAdUnitID;
- (instancetype)initWithMediatorCatalog:(NSArray<CLXMediatorConfiguration *> *)mediatorCatalog
                        mediatorsByName:(NSDictionary<NSString *, CLXMediatorConfiguration *> *)mediatorsByName
                      loadPlansByAdUnitID:(NSDictionary<NSString *, CLXLoadPlan *> *)loadPlansByAdUnitID NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface CLXSDKConfigResponse ()
@property (nonatomic, strong) CLXOrchestratorConfiguration *orchestratorConfiguration;
@end

NS_ASSUME_NONNULL_END
