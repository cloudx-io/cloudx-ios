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
        _osLog = os_log_create("io.cloudx.sdk", category.UTF8String);
    }
    return self;
}

- (void)setLoggingEnabled:(BOOL)enabled {
    _globalLoggingEnabled = enabled;
}

- (NSString *)timestampedMessage:(NSString *)message {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSS"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    return [NSString stringWithFormat:@"[%@] %@", timestamp, message];
}

- (void)log:(NSString *)message type:(os_log_type_t)type {
    NSString *msgWithTimestamp = [self timestampedMessage:message];

    // Always show errors for debuggability
    if (type == OS_LOG_TYPE_ERROR) {
        NSLog(@"%@", msgWithTimestamp);
        os_log_with_type(self.osLog, type, "%{public}@", msgWithTimestamp);
        return;
    }
    
    // Debug/Info only if verbose logging enabled
    if (!_globalLoggingEnabled) {
        return;
    }
    
    // Use NSLog for Xcode console output (publishers expect console visibility)
    // Note: Skipping os_log for debug/info to avoid duplication in Xcode console
    // Publishers can enable system logging via Console.app if needed, but most debug in Xcode

    NSLog(@"%@", msgWithTimestamp);
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
