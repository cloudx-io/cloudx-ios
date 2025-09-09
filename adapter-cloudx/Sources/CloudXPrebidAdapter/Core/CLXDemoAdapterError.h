//
//  CloudXDemoAdapterError.h
//  CloudXTestVastNetworkAdapter
//
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