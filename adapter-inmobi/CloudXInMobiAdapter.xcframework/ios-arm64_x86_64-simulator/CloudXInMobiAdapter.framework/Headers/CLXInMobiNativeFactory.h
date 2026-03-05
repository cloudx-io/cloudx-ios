//
//  CLXInMobiNativeFactory.h
//  CloudXInMobiAdapter
//
//  Created by CloudX Team.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CloudXCore.h>

@class CLXLogger;

NS_ASSUME_NONNULL_BEGIN

@interface CLXInMobiNativeFactory : NSObject <CLXAdapterNativeFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END

