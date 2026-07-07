//
//  CLXMetaUtils.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterLogger.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CLXAdapterLogger;

@interface CLXMetaUtils : NSObject

+ (NSString *)resolveMetaPlacementID:(NSDictionary<NSString *, NSString *> *)extras
                          fallbackAdId:(NSString *)adId
                                logger:(id<CLXAdapterLogger>)logger;

@end

NS_ASSUME_NONNULL_END
