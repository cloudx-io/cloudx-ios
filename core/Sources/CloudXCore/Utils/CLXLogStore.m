/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/CLXLogStore.h>
#import <CloudXCore/CLXUserDefaultsKeys.h>
#import <CloudXCore/CloudXCoreAPI.h>

static const NSUInteger kCLXMaxLogEntries = 1000;

@interface CLXLogStore ()
@property (nonatomic, strong) NSMutableArray<CLXLogEntry *> *logs;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation CLXLogStore

+ (NSUInteger)maxLogEntries {
    return kCLXMaxLogEntries;
}

+ (instancetype)shared {
    static CLXLogStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _logs = [NSMutableArray arrayWithCapacity:kCLXMaxLogEntries];
        _queue = dispatch_queue_create("io.cloudx.sdk.logstore", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (BOOL)isEnabled {
    // Log collection is enabled when either testMode OR visualDebugging is enabled
    // This allows debugging of real production ads when visualDebugging is enabled separately
    return [[NSUserDefaults standardUserDefaults] boolForKey:kCLXCoreTestModeKey] ||
           [CloudXCore isVisualDebuggingEnabled];
}

- (void)addEntry:(CLXLogEntry *)entry {
    if (![self isEnabled]) {
        return;
    }
    
    if (!entry) {
        return;
    }
    
    dispatch_async(self.queue, ^{
        // LRU eviction: remove oldest if at capacity
        if (self.logs.count >= kCLXMaxLogEntries) {
            [self.logs removeObjectAtIndex:0];
        }
        [self.logs addObject:entry];
    });
}

- (NSArray<CLXLogEntry *> *)allEntries {
    __block NSArray<CLXLogEntry *> *result;
    dispatch_sync(self.queue, ^{
        // Return in reverse order (newest first)
        result = [[self.logs reverseObjectEnumerator] allObjects];
    });
    return result;
}

- (NSUInteger)count {
    __block NSUInteger result;
    dispatch_sync(self.queue, ^{
        result = self.logs.count;
    });
    return result;
}

- (void)clear {
    dispatch_sync(self.queue, ^{
        [self.logs removeAllObjects];
    });
}

- (NSString *)exportAsString {
    NSArray<CLXLogEntry *> *entries = [self allEntries];
    
    if (entries.count == 0) {
        return @"No logs captured.";
    }
    
    NSMutableString *result = [NSMutableString stringWithFormat:@"CloudX SDK Debug Logs (%lu entries)\n", (unsigned long)entries.count];
    [result appendString:@"========================================\n\n"];
    
    for (CLXLogEntry *entry in entries) {
        [result appendFormat:@"%@\n", [entry formattedString]];
    }
    
    return result;
}

@end

