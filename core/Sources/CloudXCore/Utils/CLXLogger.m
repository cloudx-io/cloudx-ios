//
// Logger.m
// CloudXCore
//

#import <CloudXCore/CLXLogger.h>
#import <os/log.h>

// Class-level logging flag that affects all logger instances
static BOOL _globalLoggingEnabled = NO;

@interface CLXLogger ()
@property (nonatomic, copy) NSString *category;
@property (nonatomic, strong) os_log_t osLog;
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
        
        // Create os_log for system logging
        _osLog = os_log_create("io.cloudx.sdk", category.UTF8String);
    }
    return self;
}

- (void)setLoggingEnabled:(BOOL)enabled {
    _globalLoggingEnabled = enabled;
}


- (void)log:(NSString *)message type:(os_log_type_t)type {
    if (!_globalLoggingEnabled) {
        return;
    }
    
    // Use NSLog for console output (visible in Xcode console and Flutter console)
    NSLog(@"%@", message);
    
    // Use os_log for system logging (visible in Console.app and device logs)
    os_log_with_type(self.osLog, type, "%{public}@", message);
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