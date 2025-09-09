#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol for SKAdNetwork constants
@protocol CLXSKAdNetworkConstants <NSObject>
@property (nonatomic, readonly, nullable) NSArray<NSString *> *skadPlistIds;
@property (nonatomic, readonly) NSArray<NSString *> *versions;
@property (nonatomic, readonly) NSString *sourceApp;
@end

/// SKAdNetworkService implementation
@interface CLXSKAdNetworkService : NSObject <CLXSKAdNetworkConstants>

- (instancetype)initWithSystemVersion:(NSString *)systemVersion;

@end

NS_ASSUME_NONNULL_END 