//
//  CloudXDemoAdapterError.m
//  CloudXTestVastNetworkAdapter
//
//

#import "CLXDemoAdapterError.h"

@implementation CLXDemoAdapterError

+ (NSError *)invalidAdmError {
    return [NSError errorWithDomain:@"com.cloudx.demo.adapter"
                            code:CLXDemoAdapterErrorCodeInvalidAdm
                        userInfo:@{NSLocalizedDescriptionKey: @"Invalid Ad Markup (adm)"}];
}

@end 