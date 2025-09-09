//
// Logger.m
// CloudXCore
//

#import <CloudXCore/CLXLogger.h>
#import <os/log.h>

@interface CLXLogger ()
@property (nonatomic, copy) NSString *category;
@property (nonatomic, strong) os_log_t osLog;
@property (nonatomic, assign) BOOL verbose;
@property (nonatomic, assign) BOOL flutterVerbose;
@end

@implementation CLXLogger

+ (instancetype)shared {
    static CLXLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithCategory:@"cloudx-sdk"];
    });
    return sharedInstance;
}

- (instancetype)initWithCategory:(NSString *)category {
    self = [super init];
    if (self) {
        _category = [category copy];
        
        // Check environment variables for logging control
        NSString *verboseLog = [[NSProcessInfo processInfo] environment][@"CLOUDX_VERBOSE_LOG"];
        NSString *flutterVerboseLog = [[NSProcessInfo processInfo] environment][@"CLOUDX_FLUTTER_VERBOSE_LOG"];
        
        // Set up logging based on environment variables
        _verbose = [verboseLog isEqualToString:@"1"];
        _flutterVerbose = [flutterVerboseLog isEqualToString:@"1"];
        
        // Create os_log if we need system logging (either verbose flag)
        // Note: os_log entries won't appear in Flutter console, but will be visible in:
        // - Xcode Console app (Window > Devices and Simulators > View Device Logs)
        // - Device logs via Xcode's Console app
        // - System logs when debugging on device
        if (_verbose || _flutterVerbose) {
            _osLog = os_log_create("io.cloudx.sdk", category.UTF8String);
        } else {
            _osLog = OS_LOG_DISABLED;
        }
    }
    return self;
}


- (void)log:(NSString *)message type:(os_log_type_t)type {
    // Use NSLog for Flutter verbose logging (console output)
    // Note: os_log entries won't appear in Flutter console, but will be visible in:
    // - Xcode Console app (Window > Devices and Simulators > View Device Logs)
    // - Device logs via Xcode's Console app
    // - System logs when debugging on device
    if (self.flutterVerbose) {
        NSLog(@"%@", message);
    }
    
    // Use os_log for system logging (both verbose flags)
    // Note: os_log entries won't appear in Flutter console, but will be visible in:
    // - Xcode Console app (Window > Devices and Simulators > View Device Logs)
    // - Device logs via Xcode's Console app
    // - System logs when debugging on device
    if (self.verbose || self.flutterVerbose) {
        os_log_with_type(self.osLog, type, "%{public}@", message);
    }
}

- (void)debug:(NSString *)message {
    [self log:message type:OS_LOG_TYPE_DEBUG];
}

- (void)info:(NSString *)message {
    [self log:message type:OS_LOG_TYPE_INFO];
}

- (void)error:(NSString *)message {
    [self log:message type:OS_LOG_TYPE_ERROR];
}

@end 