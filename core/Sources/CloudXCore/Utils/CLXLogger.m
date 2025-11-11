//
// Logger.m
// CloudXCore
//

#import <CloudXCore/CLXLogger.h>
#import <os/log.h>

// Class-level logging flags that affect all logger instances
static BOOL _globalLoggingEnabled = YES;
static CLXLogLevel _globalMinLogLevel = CLXLogLevelError;
static BOOL _globalEmojisEnabled = YES;

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

- (void)setMinLogLevel:(CLXLogLevel)minLogLevel {
    _globalMinLogLevel = minLogLevel;
}

- (void)setEmojisEnabled:(BOOL)enabled {
    _globalEmojisEnabled = enabled;
}

#pragma mark - Emoji and Level Name Mapping

- (NSString *)emojiForType:(CLXLogEmoji)emojiType {
    if (!_globalEmojisEnabled) {
        return @"";
    }
    
    switch (emojiType) {
        case CLXLogEmojiError:   return @"❌";
        case CLXLogEmojiWarn:    return @"⚠️";
        case CLXLogEmojiInfo:    return @"ℹ️";
        case CLXLogEmojiDebug:   return @"🐛";
        case CLXLogEmojiVerbose: return @"🔍";
        case CLXLogEmojiSuccess: return @"✅";
        case CLXLogEmojiEvent:   return @"🎉";
        default:                 return @"";
    }
}

- (NSString *)emojiTypeNameForType:(CLXLogEmoji)emojiType {
    if (_globalEmojisEnabled) {
        return @"";  // No text prefix when emojis are shown
    }
    
    // When emojis disabled, use text prefix for Success/Event
    switch (emojiType) {
        case CLXLogEmojiSuccess: return @"SUCCESS ";
        case CLXLogEmojiEvent:   return @"EVENT ";
        default:                 return @"";
    }
}

- (NSString *)levelNameForLevel:(CLXLogLevel)level {
    switch (level) {
        case CLXLogLevelVerbose: return @"VERBOSE";
        case CLXLogLevelDebug:   return @"DEBUG";
        case CLXLogLevelInfo:    return @"INFO";
        case CLXLogLevelWarn:    return @"WARN";
        case CLXLogLevelError:   return @"ERROR";
        default:                 return @"UNKNOWN";
    }
}

- (os_log_type_t)osLogTypeForLevel:(CLXLogLevel)level {
    switch (level) {
        case CLXLogLevelVerbose: return OS_LOG_TYPE_DEBUG;
        case CLXLogLevelDebug:   return OS_LOG_TYPE_DEBUG;
        case CLXLogLevelInfo:    return OS_LOG_TYPE_INFO;
        case CLXLogLevelWarn:    return OS_LOG_TYPE_DEFAULT;
        case CLXLogLevelError:   return OS_LOG_TYPE_ERROR;
        default:                 return OS_LOG_TYPE_DEBUG;
    }
}

#pragma mark - Core Logging Method

- (void)logAtLevel:(CLXLogLevel)level 
         emojiType:(CLXLogEmoji)emojiType 
           message:(NSString *)message {
    
    // Check if level should be suppressed
    if (level < _globalMinLogLevel) {
        return;
    }
    
    // Check if logging is enabled (except for errors which always show)
    if (level != CLXLogLevelError && !_globalLoggingEnabled) {
        return;
    }
    
    // Format: [CloudX] <emoji> <LEVEL>  | ClassName - message
    NSString *emoji = [self emojiForType:emojiType];
    NSString *typePrefix = [self emojiTypeNameForType:emojiType];
    NSString *levelName = [self levelNameForLevel:level];
    
    NSString *formattedMessage;
    if (emoji.length > 0) {
        // With emojis: [CloudX] <emoji> <LEVEL>  | ClassName - message
        formattedMessage = [NSString stringWithFormat:@"[CloudX] %@ %@ | %@ - %@", 
                           emoji, levelName, self.category, message];
    } else if (typePrefix.length > 0) {
        // Without emojis, with type prefix: [CloudX] <TYPE> <LEVEL>  | ClassName - message
        formattedMessage = [NSString stringWithFormat:@"[CloudX] %@%@ | %@ - %@", 
                           typePrefix, levelName, self.category, message];
    } else {
        // Without emojis, no type: [CloudX] <LEVEL>  | ClassName - message
        formattedMessage = [NSString stringWithFormat:@"[CloudX] %@ | %@ - %@", 
                           levelName, self.category, message];
    }
    
    // Log using os_log (Xcode console shows these automatically)
    os_log_type_t osLogType = [self osLogTypeForLevel:level];
    os_log_with_type(self.osLog, osLogType, "%{public}@", formattedMessage);
}

#pragma mark - Convenience Methods

- (void)verbose:(NSString *)message {
    [self logAtLevel:CLXLogLevelVerbose emojiType:CLXLogEmojiVerbose message:message];
}

- (void)debug:(NSString *)message {
    [self logAtLevel:CLXLogLevelDebug emojiType:CLXLogEmojiDebug message:message];
}

- (void)info:(NSString *)message {
    [self logAtLevel:CLXLogLevelInfo emojiType:CLXLogEmojiInfo message:message];
}

- (void)warn:(NSString *)message {
    [self logAtLevel:CLXLogLevelWarn emojiType:CLXLogEmojiWarn message:message];
}

- (void)error:(NSString *)message {
    [self logAtLevel:CLXLogLevelError emojiType:CLXLogEmojiError message:message];
}

- (void)success:(NSString *)message {
    [self logAtLevel:CLXLogLevelInfo emojiType:CLXLogEmojiSuccess message:message];
}

- (void)event:(NSString *)message {
    [self logAtLevel:CLXLogLevelInfo emojiType:CLXLogEmojiEvent message:message];
}

@end
