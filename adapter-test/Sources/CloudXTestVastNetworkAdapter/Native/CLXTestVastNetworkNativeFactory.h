//
//  CloudXTestVastNetworkNativeFactory.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 06.04.2024.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CloudXCore/CloudXCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLXTestVastNetworkNativeFactory : NSObject <CLXAdapterNativeFactory>

+ (instancetype)createInstance;

@end

NS_ASSUME_NONNULL_END 