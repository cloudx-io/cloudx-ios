#import <CloudXCore/UIDevice+CLXIdentifier.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation UIDevice (CLXIdentifier)

+ (NSString *)clx_deviceIdentifier {
    static NSString *identifier = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname systemInfo;
        uname(&systemInfo);
        identifier = @(systemInfo.machine);
    });
    return identifier;
}

+ (NSString *)clx_deviceType {
    return [self clx_mapToDeviceWithIdentifier:self.clx_deviceIdentifier][@"deviceType"];
}

+ (NSString *)clx_deviceGeneration {
    return [self clx_mapToDeviceWithIdentifier:self.clx_deviceIdentifier][@"deviceGeneration"];
}

+ (NSInteger)clx_ppi {
    return [[self clx_mapToDeviceWithIdentifier:self.clx_deviceIdentifier][@"ppi"] integerValue];
}

#pragma mark - Fallback for Unknown Devices

/// Generates fallback device info for unknown device identifiers.
/// Parses the identifier to extract device type and uses the identifier as the generation.
/// This ensures future devices always return meaningful values without SDK updates.
+ (NSDictionary<NSString *, id> *)clx_fallbackDeviceInfoForIdentifier:(NSString *)identifier {
    NSString *deviceType = @"Unknown";
    NSInteger defaultPPI = 460; // Modern device default
    
    // Parse device type from identifier prefix
    if ([identifier hasPrefix:@"iPhone"]) {
        deviceType = @"iPhone";
    } else if ([identifier hasPrefix:@"iPad"]) {
        deviceType = @"iPad";
        defaultPPI = 264;
    } else if ([identifier hasPrefix:@"iPod"]) {
        deviceType = @"iPod";
        defaultPPI = 326;
    } else if ([identifier hasPrefix:@"AppleTV"]) {
        deviceType = @"AppleTV";
        defaultPPI = 0;
    } else if ([identifier hasPrefix:@"Watch"]) {
        deviceType = @"Watch";
        defaultPPI = 326;
    } else if ([identifier containsString:@"arm64"] || [identifier containsString:@"x86"] || [identifier containsString:@"i386"]) {
        deviceType = @"Simulator";
        defaultPPI = 264;
    }
    
    // Use the raw identifier as the generation for unknown devices.
    // This provides more value to bidders than an empty string.
    return @{
        @"deviceType": deviceType,
        @"deviceGeneration": identifier,
        @"ppi": @(defaultPPI)
    };
}

+ (NSDictionary<NSString *, id> *)clx_mapToDeviceWithIdentifier:(NSString *)identifier {
    // Device map for known devices. For unknown devices, clx_fallbackDeviceInfoForIdentifier
    // extracts the device type from the identifier prefix and uses the identifier as generation.
    // This approach is future-proof: new devices automatically get reasonable values.
    static NSDictionary *deviceMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        deviceMap = @{
            // iPhone 4-6 series (legacy, rarely seen)
            @"iPhone3,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"4", @"ppi": @326},
            @"iPhone4,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"4s", @"ppi": @326},
            @"iPhone5,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"5", @"ppi": @326},
            @"iPhone6,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"5s", @"ppi": @326},
            @"iPhone7,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"6 Plus", @"ppi": @401},
            @"iPhone7,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"6", @"ppi": @326},
            @"iPhone8,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"6s", @"ppi": @326},
            @"iPhone8,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"6s Plus", @"ppi": @401},
            @"iPhone8,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"SE", @"ppi": @326},
            
            // iPhone 7-8/X series
            @"iPhone9,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"7", @"ppi": @326},
            @"iPhone9,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"7", @"ppi": @326},
            @"iPhone10,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"8", @"ppi": @326},
            @"iPhone10,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"X", @"ppi": @458},
            @"iPhone10,6": @{@"deviceType": @"iPhone", @"deviceGeneration": @"X", @"ppi": @458},
            
            // iPhone XS/XR/11 series
            @"iPhone11,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"XS", @"ppi": @458},
            @"iPhone11,8": @{@"deviceType": @"iPhone", @"deviceGeneration": @"XR", @"ppi": @326},
            @"iPhone12,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"11", @"ppi": @326},
            @"iPhone12,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"11 Pro", @"ppi": @458},
            @"iPhone12,8": @{@"deviceType": @"iPhone", @"deviceGeneration": @"SE 2", @"ppi": @326},
            
            // iPhone 12-13 series
            @"iPhone13,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"12 mini", @"ppi": @476},
            @"iPhone13,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"12", @"ppi": @460},
            @"iPhone14,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"13 Pro", @"ppi": @460},
            @"iPhone14,5": @{@"deviceType": @"iPhone", @"deviceGeneration": @"13", @"ppi": @460},
            @"iPhone14,6": @{@"deviceType": @"iPhone", @"deviceGeneration": @"SE 3", @"ppi": @326},
            
            // iPhone 14 series
            @"iPhone14,7": @{@"deviceType": @"iPhone", @"deviceGeneration": @"14", @"ppi": @460},
            @"iPhone14,8": @{@"deviceType": @"iPhone", @"deviceGeneration": @"14 Plus", @"ppi": @458},
            @"iPhone15,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"14 Pro", @"ppi": @460},
            @"iPhone15,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"14 Pro Max", @"ppi": @460},
            
            // iPhone 15 series
            @"iPhone15,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"15", @"ppi": @460},
            @"iPhone15,5": @{@"deviceType": @"iPhone", @"deviceGeneration": @"15 Plus", @"ppi": @460},
            @"iPhone16,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"15 Pro", @"ppi": @460},
            @"iPhone16,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"15 Pro Max", @"ppi": @460},
            
            // iPhone 16 series
            @"iPhone17,1": @{@"deviceType": @"iPhone", @"deviceGeneration": @"16 Pro", @"ppi": @460},
            @"iPhone17,2": @{@"deviceType": @"iPhone", @"deviceGeneration": @"16 Pro Max", @"ppi": @460},
            @"iPhone17,3": @{@"deviceType": @"iPhone", @"deviceGeneration": @"16", @"ppi": @460},
            @"iPhone17,4": @{@"deviceType": @"iPhone", @"deviceGeneration": @"16 Plus", @"ppi": @460},
            
            // Simulators
            @"i386": @{@"deviceType": @"Simulator", @"deviceGeneration": @"32-bit", @"ppi": @264},
            @"x86_64": @{@"deviceType": @"Simulator", @"deviceGeneration": @"64-bit", @"ppi": @264},
            @"arm64": @{@"deviceType": @"Simulator", @"deviceGeneration": @"Apple Silicon", @"ppi": @264}
        };
    });
    
    NSDictionary *deviceInfo = deviceMap[identifier];
    if (!deviceInfo) {
        // Fallback: parse the identifier to provide meaningful values for future devices
        return [self clx_fallbackDeviceInfoForIdentifier:identifier];
    }
    return deviceInfo;
}

@end
