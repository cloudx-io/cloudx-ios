#import "DemoAppLogger.h"
#import <CloudXCore/CloudXCore.h>

@implementation DemoAppLogEntry

- (instancetype)initWithMessage:(NSString *)message {
    self = [super init];
    if (self) {
        _message = [message copy];
        _timestamp = [NSDate date];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm:ss.SSS";
        _formattedTimestamp = [formatter stringFromDate:_timestamp];
    }
    return self;
}

@end

@interface DemoAppLogger ()
@property (nonatomic, strong) NSMutableArray<DemoAppLogEntry *> *logs;
@property (nonatomic, strong) dispatch_queue_t logQueue;
@end

@implementation DemoAppLogger

+ (instancetype)sharedInstance {
    static DemoAppLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DemoAppLogger alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logs = [[NSMutableArray alloc] init];
        _logQueue = dispatch_queue_create("com.cloudx.demo.logger", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)logMessage:(NSString *)message {
    if (!message) return;
    
    dispatch_async(self.logQueue, ^{
        DemoAppLogEntry *entry = [[DemoAppLogEntry alloc] initWithMessage:message];
        [self.logs addObject:entry];
        
        // Keep only the last 500 logs to prevent memory issues
        if (self.logs.count > 500) {
            [self.logs removeObjectAtIndex:0];
        }
    });
}

- (void)logAdEvent:(NSString *)eventName ad:(nullable CLXAd *)ad {
    if (!eventName) return;
    
    NSString *adDetails = [DemoAppLogger formatAdDetails:ad];
    NSString *fullMessage = [NSString stringWithFormat:@"%@%@", eventName, adDetails];
    [self logMessage:fullMessage];
}

- (void)clearLogs {
    dispatch_async(self.logQueue, ^{
        [self.logs removeAllObjects];
    });
}

- (NSArray<DemoAppLogEntry *> *)getAllLogs {
    __block NSArray<DemoAppLogEntry *> *logsCopy;
    dispatch_sync(self.logQueue, ^{
        logsCopy = [self.logs copy];
    });
    return logsCopy;
}

- (NSInteger)logCount {
    __block NSInteger count;
    dispatch_sync(self.logQueue, ^{
        count = self.logs.count;
    });
    return count;
}

+ (NSString *)formatAdDetails:(nullable CLXAd *)ad {
    if (!ad) {
        return @" - Ad: (null)";
    }
    
    NSMutableString *details = [NSMutableString stringWithString:@" - Ad Details:"];
    
    // Placement Name
    if (ad.placementName) {
        [details appendFormat:@"\n  📍 Placement: %@", ad.placementName];
    } else {
        [details appendString:@"\n  📍 Placement: (null)"];
    }
    
    // Placement ID
    if (ad.placementId) {
        [details appendFormat:@"\n  🆔 Placement ID: %@", ad.placementId];
    } else {
        [details appendString:@"\n  🆔 Placement ID: (null)"];
    }
    
    // Bidder/Network
    if (ad.bidder) {
        [details appendFormat:@"\n  🏢 Bidder: %@", ad.bidder];
    } else {
        [details appendString:@"\n  🏢 Bidder: (null)"];
    }
    
    // External Placement ID
    if (ad.externalPlacementId) {
        [details appendFormat:@"\n  🔗 External ID: %@", ad.externalPlacementId];
    } else {
        [details appendString:@"\n  🔗 External ID: (null)"];
    }
    
    // Revenue
    if (ad.revenue) {
        [details appendFormat:@"\n  💰 Revenue: $%.6f", [ad.revenue doubleValue]];
    } else {
        [details appendString:@"\n  💰 Revenue: (null)"];
    }
    
    return [details copy];
}

@end
