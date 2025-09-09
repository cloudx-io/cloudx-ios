//
//  CloudXDemoAdapterError.h
//  CloudXTestVastNetworkAdapter
//
//  Created by bkorda on 07.03.2024.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CLXDemoAdapterErrorCode) {
    CLXDemoAdapterErrorCodeInvalidAdm
};

@interface CLXDemoAdapterError : NSObject

+ (NSError *)invalidAdmError;

@end

NS_ASSUME_NONNULL_END 