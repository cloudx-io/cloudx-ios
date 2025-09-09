//
//  SDKConfigEndpointObject.h
//  CloudXCore
//
//  Created by Bryan Boyko on 6/20/25.
//

#import <Foundation/Foundation.h>
#import <CloudXCore/CLXSDKConfig.h>

NS_ASSUME_NONNULL_BEGIN

// Implementation methods for SDKConfigEndpointValue
@interface CLXSDKConfigEndpointValue (Implementation)
- (instancetype)initWithName:(nullable NSString *)name 
                       value:(NSString *)value 
                        ratio:(double)ratio;
@end

// Implementation methods for SDKConfigEndpointObject
@interface CLXSDKConfigEndpointObject (Implementation)
- (instancetype)initWithTest:(nullable NSArray<CLXSDKConfigEndpointValue *> *)test 
                  defaultKey:(NSString *)defaultKey;
@end

NS_ASSUME_NONNULL_END 