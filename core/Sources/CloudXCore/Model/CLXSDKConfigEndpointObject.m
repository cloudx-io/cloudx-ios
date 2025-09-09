//
//  SDKConfigEndpointObject.m
//  CloudXCore
//
//  Created by Bryan Boyko on 6/20/25.
//

#import <CloudXCore/CLXSDKConfigEndpointObject.h>

@implementation CLXSDKConfigEndpointValue

- (instancetype)init {
    self = [super init];
    if (self) {
        _name = @"";
        _value = @"";
        _ratio = 0.0;
    }
    return self;
}

- (instancetype)initWithName:(nullable NSString *)name 
                       value:(NSString *)value 
                        ratio:(double)ratio {
    self = [super init];
    if (self) {
        _name = [name copy];
        _value = [value copy];
        _ratio = ratio;
    }
    return self;
}

@end

@implementation CLXSDKConfigEndpointObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _test = [NSArray array];
        _defaultKey = @"";
    }
    return self;
}

- (instancetype)initWithTest:(nullable NSArray<CLXSDKConfigEndpointValue *> *)test 
                  defaultKey:(NSString *)defaultKey {
    self = [super init];
    if (self) {
        _test = test;
        _defaultKey = [defaultKey copy];
    }
    return self;
}

@end 