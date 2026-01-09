//
// Logger.m
// CloudXCore
//

#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXLogStore.h>
#import <CloudXCore/CLXLogEntry.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXError.h>
#import <os/log.h>

// Class-level logging flags that affect all logger instances
static CLXLogLevel _globalMinLogLevel = CLXLogLevelError;
static BOOL _globalEmojisEnabled = YES;
static BOOL _globalTimestampsEnabled = NO;

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

- (void)setMinLogLevel:(CLXLogLevel)minLogLevel {
    _globalMinLogLevel = minLogLevel;
}

- (void)setEmojisEnabled:(BOOL)enabled {
    _globalEmojisEnabled = enabled;
}

- (void)setTimestampsEnabled:(BOOL)enabled {
    _globalTimestampsEnabled = enabled;
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
        case CLXLogLevelNone:    return @"NONE";
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
        case CLXLogLevelNone:
            // CLXLogLevelNone is only valid as a minLogLevel threshold, not as a message level
            NSAssert(NO, @"CLXLogLevelNone should not be used as a log message level");
            return OS_LOG_TYPE_DEBUG;
        default:                 return OS_LOG_TYPE_DEBUG;
    }
}

#pragma mark - Core Logging Method

- (void)logAtLevel:(CLXLogLevel)level 
         emojiType:(CLXLogEmoji)emojiType 
           message:(NSString *)message {
    
    // Check if level should be suppressed (CLXLogLevelNone disables all logging)
    if (level < _globalMinLogLevel) {
        return;
    }

    // Format: [CloudX] <timestamp?> <emoji> <LEVEL>  | ClassName - message
    NSString *emoji = [self emojiForType:emojiType];
    NSString *typePrefix = [self emojiTypeNameForType:emojiType];
    NSString *levelName = [self levelNameForLevel:level];
    
    // Generate timestamp if enabled
    NSString *timestamp = @"";
    if (_globalTimestampsEnabled) {
        static NSDateFormatter *timestampFormatter = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            timestampFormatter = [[NSDateFormatter alloc] init];
            [timestampFormatter setDateFormat:@"HH:mm:ss.SSS"];
        });
        timestamp = [NSString stringWithFormat:@"[%@] ", [timestampFormatter stringFromDate:[NSDate date]]];
    }
    
    NSString *formattedMessage;
    if (emoji.length > 0) {
        // With emojis: [CloudX] [timestamp?] <emoji> <LEVEL>  | ClassName - message
        formattedMessage = [NSString stringWithFormat:@"[CloudX] %@%@ %@ | %@ - %@", 
                           timestamp, emoji, levelName, self.category, message];
    } else if (typePrefix.length > 0) {
        // Without emojis, with type prefix: [CloudX] [timestamp?] <TYPE> <LEVEL>  | ClassName - message
        formattedMessage = [NSString stringWithFormat:@"[CloudX] %@%@%@ | %@ - %@", 
                           timestamp, typePrefix, levelName, self.category, message];
    } else {
        // Without emojis, no type: [CloudX] [timestamp?] <LEVEL>  | ClassName - message
        formattedMessage = [NSString stringWithFormat:@"[CloudX] %@%@ | %@ - %@", 
                           timestamp, levelName, self.category, message];
    }
    
    // Log using os_log (Xcode console shows these automatically)
    os_log_type_t osLogType = [self osLogTypeForLevel:level];
    os_log_with_type(self.osLog, osLogType, "%{public}@", formattedMessage);
    
    // Store in log buffer when testMode is enabled
    // Include emoji prefix in stored message for better readability
    NSString *storedMessage = emoji.length > 0 
        ? [NSString stringWithFormat:@"%@ %@", emoji, message]
        : message;
    CLXLogEntry *entry = [[CLXLogEntry alloc] initWithLevel:level
                                                   category:self.category
                                                    message:storedMessage];
    [[CLXLogStore shared] addEntry:entry];
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

#pragma mark - Delegate Callback Logging

- (void)logDelegateCallback:(NSString *)callbackName ad:(CLXAd *)ad {
    NSMutableString *message = [NSMutableString stringWithString:callbackName];
    
    if (ad) {
        [message appendString:@"\n  📍 Placement: "];
        [message appendString:ad.placementName ?: @"(null)"];
        
        [message appendString:@"\n  🆔 Placement ID: "];
        [message appendString:ad.placementId ?: @"(null)"];
        
        [message appendString:@"\n  🏢 Bidder: "];
        [message appendString:ad.bidder ?: @"(null)"];
        
        [message appendString:@"\n  🔗 External ID: "];
        [message appendString:ad.externalPlacementId ?: @"(null)"];
        
        [message appendString:@"\n  💰 Revenue: "];
        if (ad.revenue) {
            [message appendFormat:@"$%.6f", ad.revenue.doubleValue];
        } else {
            [message appendString:@"(null)"];
        }
    } else {
        [message appendString:@" - Ad: (null)"];
    }
    
    [self logAtLevel:CLXLogLevelInfo emojiType:CLXLogEmojiInfo message:message];
}

- (void)logDelegateError:(NSString *)callbackName error:(CLXError *)error {
    NSMutableString *message = [NSMutableString stringWithString:callbackName];
    
    if (error) {
        [message appendString:@"\n  ⚠️ Error: "];
        [message appendString:error.localizedDescription ?: @"Unknown error"];
        
        if (error.code != 0) {
            [message appendFormat:@"\n  🔢 Code: %ld", (long)error.code];
        }
    } else {
        [message appendString:@" - Error: (null)"];
    }
    
    [self logAtLevel:CLXLogLevelError emojiType:CLXLogEmojiError message:message];
}

@end
