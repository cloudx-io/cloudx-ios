//
//  CLXInMobiInitializer.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXAdapterInitializer.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiInitializer : CLXAdapterInitializer

+ (NSString *)sdkVersion;
+ (NSDictionary<NSString *, NSString *> *)extras;

@end

NS_ASSUME_NONNULL_END
