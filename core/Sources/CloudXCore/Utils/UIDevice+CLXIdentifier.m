#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation UIDevice (Identifier)

+ (NSString *)deviceIdentifier {
    static NSString *identifier = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *machine = @(systemInfo.machine);
        identifier = machine;
    });
    return identifier;
}

+ (NSString *)deviceType {
    return [self mapToDeviceWithIdentifier:self.deviceIdentifier][@"deviceType"];
}

+ (NSString *)deviceGeneration {
    return [self mapToDeviceWithIdentifier:self.deviceIdentifier][@"deviceGeneration"];
}

+ (NSInteger)ppi {
    return [[self mapToDeviceWithIdentifier:self.deviceIdentifier][@"ppi"] integerValue];
}

+ (NSDictionary<NSString *, id> *)mapToDeviceWithIdentifier:(NSString *)identifier {
    static NSDictionary *deviceMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        deviceMap = @{
            @"iPhone3,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"4", @"ppi": @326},
            @"iPhone3,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"4", @"ppi": @326},
            @"iPhone3,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"4", @"ppi": @326},
            @"iPhone4,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"4s", @"ppi": @326},
            @"iPhone5,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"5", @"ppi": @326},
            @"iPhone5,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"5", @"ppi": @326},
            @"iPhone5,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"5c", @"ppi": @326},
            @"iPhone5,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"5c", @"ppi": @326},
            @"iPhone6,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"5s", @"ppi": @326},
            @"iPhone6,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"5s", @"ppi": @326},
            @"iPhone7,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"6 Plus", @"ppi": @401},
            @"iPhone7,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"6", @"ppi": @326},
            @"iPhone8,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"6s", @"ppi": @326},
            @"iPhone8,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"6s Plus", @"ppi": @401},
            @"iPhone8,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"SE", @"ppi": @326},
            @"iPhone9,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"7", @"ppi": @326},
            @"iPhone9,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"7 Plus", @"ppi": @401},
            @"iPhone9,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"7", @"ppi": @326},
            @"iPhone9,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"7 Plus", @"ppi": @401},
            @"iPhone10,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"8", @"ppi": @326},
            @"iPhone10,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"8 Plus", @"ppi": @401},
            @"iPhone10,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"X", @"ppi": @458},
            @"iPhone10,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"8", @"ppi": @326},
            @"iPhone10,5": @{@"deviceType": @"iPhone", @"deviceGeneration": @"8 Plus", @"ppi": @401},
            @"iPhone10,6": @{@"deviceType": @"iPhone", @"deviceGeneration": @"X", @"ppi": @458},
            @"iPhone11,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"XS", @"ppi": @458},
            @"iPhone11,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"XS Max", @"ppi": @458},
            @"iPhone11,6": @{@"deviceType": @"iPhone", @"deviceGeneration": @"XS Max", @"ppi": @458},
            @"iPhone11,8": @{@"deviceType": @"iPhone", @"deviceGeneration": @"XR", @"ppi": @326},
            @"iPhone12,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"11", @"ppi": @326},
            @"iPhone12,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"11 Pro", @"ppi": @458},
            @"iPhone12,5": @{@"deviceType": @"iPhone", @"deviceGeneration": @"11 Pro Max", @"ppi": @458},
            @"iPhone12,8": @{@"deviceType": @"iPhone", @"deviceGeneration": @"SE (2nd generation)", @"ppi": @326},
            @"iPhone13,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"12 mini", @"ppi": @476},
            @"iPhone13,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"12", @"ppi": @460},
            @"iPhone13,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"12 Pro", @"ppi": @460},
            @"iPhone13,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"12 Pro Max", @"ppi": @458},
            @"iPhone14,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"13 Pro", @"ppi": @460},
            @"iPhone14,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"13 Pro Max", @"ppi": @458},
            @"iPhone14,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"13 mini", @"ppi": @476},
            @"iPhone14,5": @{@"deviceType": @"iPhone", @"deviceGeneration": @"13", @"ppi": @460},
            @"iPhone14,6": @{@"deviceType": @"iPhone", @"deviceGeneration": @"SE (3rd generation)", @"ppi": @326},
            @"iPhone14,7": @{@"deviceType": @"iPhone", @"deviceGeneration": @"14", @"ppi": @460},
            @"iPhone14,8": @{@"deviceType": @"iPhone", @"deviceGeneration": @"14 Plus", @"ppi": @458},
            @"iPhone15,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"14 Pro", @"ppi": @460},
            @"iPhone15,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"14 Pro Max", @"ppi": @460},
            @"iPhone15,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"15", @"ppi": @460},
            @"iPhone15,5": @{@"deviceType": @"iPhone", @"deviceGeneration": @"15 Plus", @"ppi": @460},
            @"iPhone16,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"15 Pro", @"ppi": @460},
            @"iPhone16,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"15 Pro Max", @"ppi": @460},
            @"i386": @{@"deviceType": @"Simulator", @"deviceGeneration": @"iOS", @"ppi": @264},
            @"x86_64": @{@"deviceType": @"Simulator", @"deviceGeneration": @"iOS", @"ppi": @264}
        };
    });
    
    NSDictionary *deviceInfo = deviceMap[identifier];
    if (!deviceInfo) {
        return @{@"deviceType": identifier, @"deviceGeneration": @"", @"ppi": @0};
    }
    return deviceInfo;
}

@end 