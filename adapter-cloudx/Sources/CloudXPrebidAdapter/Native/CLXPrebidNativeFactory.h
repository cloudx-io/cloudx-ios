//
//  CLXPrebidNativeFactory.h
//  CloudXPrebidAdapter
//
//  Prebid 3.0 native factory implementation
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXPrebidNativeFactory : NSObject <CLXAdapterNativeFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END 