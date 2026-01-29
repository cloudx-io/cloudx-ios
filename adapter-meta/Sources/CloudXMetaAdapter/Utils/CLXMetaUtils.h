//
//  CLXMetaUtils.h
//  CloudXMetaAdapter
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CLXLogger;

@interface CLXMetaUtils : NSObject

+ (NSString *)resolveMetaPlacementID:(NSDictionary<NSString *, NSString *> *)extras
                          fallbackAdId:(NSString *)adId
                                logger:(CLXLogger *)logger;

@end

NS_ASSUME_NONNULL_END
