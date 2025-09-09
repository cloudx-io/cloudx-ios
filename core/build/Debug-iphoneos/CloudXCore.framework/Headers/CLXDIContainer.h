#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ServiceType) {
    ServiceTypeSingleton,
    ServiceTypeNewSingleton,
    ServiceTypeNew,
    ServiceTypeAutomatic
};

@protocol CLXDIContainerProtocol <NSObject>
- (void)registerType:(Class)type instance:(id)instance;
- (nullable id)resolveType:(ServiceType)resolveType class:(Class)type;
@end

@interface CLXDIContainer : NSObject <CLXDIContainerProtocol>

+ (instancetype)shared;

- (void)registerType:(Class)type instance:(id)instance;
- (nullable id)resolveType:(ServiceType)resolveType class:(Class)type;

@end

NS_ASSUME_NONNULL_END 