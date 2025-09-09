#import <CloudXCore/CLXSDKConfigRequest.h>

@implementation CLXSDKConfigRequestFormat

- (NSDictionary *)json {
    return @{
        @"w": @(self.w),
        @"h": @(self.h)
    };
}

@end

@implementation CLXSDKConfigRequestBanner

- (NSDictionary *)json {
    NSMutableArray *formatArray = [NSMutableArray array];
    for (CLXSDKConfigRequestFormat *format in self.format) {
        [formatArray addObject:[format json]];
    }
    
    return @{
        @"format": formatArray
    };
}

@end

@implementation CLXSDKConfigRequestImp

- (NSDictionary *)json {
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"id"] = self.id ?: @"";
    
    if (self.banner) {
        json[@"banner"] = [self.banner json];
    }
    
    return json;
}

@end

@implementation CLXSDKConfigRequest

- (NSDictionary *)json {
    NSMutableArray *impArray = [NSMutableArray array];
    for (CLXSDKConfigRequestImp *imp in self.imp) {
        [impArray addObject:[imp json]];
    }
    
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"bundle"] = self.bundle ?: @"";
    json[@"os"] = self.os ?: @"";
    json[@"osVersion"] = self.osVersion ?: @"";
    json[@"model"] = self.model ?: @"";
    json[@"vendor"] = self.vendor ?: @"";
    json[@"ifa"] = self.ifa ?: @"";
    json[@"ifv"] = self.ifv ?: @"";
    json[@"sdkVersion"] = self.sdkVersion ?: @"";
    json[@"dnt"] = @(self.dnt);
    json[@"imp"] = impArray;
    json[@"id"] = self.id ?: @"";
    json[@"urlParams"] = self.urlParams ?: @{};
    
    return json;
}

@end 