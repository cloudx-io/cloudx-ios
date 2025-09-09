/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file ReachabilityService.m
 * @brief Reachability service implementation
 */

#import <CloudXCore/CLXReachabilityService.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <Foundation/Foundation.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <CloudXCore/CLXLogger.h>

// CoreTelephony is only available on physical devices, not simulator
// #if TARGET_OS_SIMULATOR
// Simulator fallback - no CoreTelephony available
// #else
// #import <CoreTelephony/CoreTelephony.h>
// #endif

NS_ASSUME_NONNULL_BEGIN

static NSString * const kReachabilityStatusChangedNotification = @"ReachabilityStatusChangedNotification";
static NSString * const kReachabilityStatusUserInfoKey = @"status";

typedef NS_ENUM(NSInteger, ReachabilityStatus) {
    ReachabilityStatusOffline,
    ReachabilityStatusOnline,
    ReachabilityStatusUnknown
};

@interface CLXReachabilityService ()
@property (nonatomic, assign) ReachabilityStatus lastConnectionStatus;
@property (nonatomic, strong) id reachabilityObserver;
@property (nonatomic, assign, nullable) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, strong) dispatch_queue_t reachabilityQueue;
@property (nonatomic, assign) ReachabilityType currentReachabilityType;
@property (nonatomic, assign) BOOL isMonitoring;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXReachabilityService

+ (instancetype)shared {
    static CLXReachabilityService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"ReachabilityService"];
        _lastConnectionStatus = ReachabilityStatusUnknown;
        _reachabilityQueue = dispatch_queue_create("com.cloudx.reachability", DISPATCH_QUEUE_SERIAL);
        _currentReachabilityType = ReachabilityTypeUnknown;
        _isMonitoring = NO;
        
        // Add observer for reachability status changes
        _reachabilityObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityStatusChangedNotification
                                                                                  object:nil
                                                                                   queue:[NSOperationQueue mainQueue]
                                                                              usingBlock:^(NSNotification * _Nonnull note) {
            NSNumber *statusNumber = note.userInfo[kReachabilityStatusUserInfoKey];
            if (statusNumber) {
                ReachabilityStatus status = [statusNumber integerValue];
                self.lastConnectionStatus = status;
            }
        }];
        
        [self setupReachability];
    }
    return self;
}

- (void)dealloc {
    if (self.reachabilityObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.reachabilityObserver];
    }
    [self stopMonitoring];
    if (_reachabilityRef) {
        SCNetworkReachabilitySetCallback(_reachabilityRef, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, NULL);
        CFRelease(_reachabilityRef);
    }
}

- (NSInteger)connectionStatus {
    return (NSInteger)self.currentReachabilityType;
}

- (void)setupReachability {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    _reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    
    if (_reachabilityRef) {
        SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
        
        if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
            if (SCNetworkReachabilitySetDispatchQueue(_reachabilityRef, _reachabilityQueue)) {
                [self.logger debug:@"Reachability monitoring started successfully"];
            } else {
                [self.logger error:@"Failed to set reachability dispatch queue"];
            }
        } else {
            [self.logger error:@"Failed to set reachability callback"];
        }
    } else {
        [self.logger error:@"Failed to create reachability reference"];
    }
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    CLXReachabilityService *service = (__bridge CLXReachabilityService *)info;
    if (service) {
        [service updateReachabilityStatus:flags];
    }
}

+ (ReachabilityStatus)reachabilityStatusFromFlags:(SCNetworkReachabilityFlags)flags {
    BOOL connectionRequired = (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0;
    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL isWWAN = (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0;
    
    if (!connectionRequired && isReachable) {
        if (isWWAN) {
            // Determine cellular connection type
#if TARGET_OS_SIMULATOR
            // Simulator fallback - return online for WWAN
            return ReachabilityStatusOnline;
#else
            // For iOS 14.0+, we can't use the deprecated constants
            // Just return online for WWAN connections
            return ReachabilityStatusOnline;
#endif
        } else {
            return ReachabilityStatusOnline; // WiFi
        }
    } else {
        return ReachabilityStatusOffline;
    }
}

- (void)startMonitoring {
    if (self.isMonitoring) {
        return;
    }
    
    dispatch_async(self.reachabilityQueue, ^{
        // Create reachability reference
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        
        self.reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
        
        if (self.reachabilityRef) {
            SCNetworkReachabilityContext context = {0, (__bridge void *)self, NULL, NULL, NULL};
            
            if (SCNetworkReachabilitySetCallback(self.reachabilityRef, ReachabilityCallback, &context)) {
                if (SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, self.reachabilityQueue)) {
                    self.isMonitoring = YES;
                    
                    // Get initial status
                    [self updateReachabilityStatus];
                }
            }
        }
    });
}

- (void)stopMonitoring {
    if (!self.isMonitoring) {
        return;
    }
    
    dispatch_async(self.reachabilityQueue, ^{
        if (self.reachabilityRef) {
            SCNetworkReachabilitySetDispatchQueue(self.reachabilityRef, NULL);
            CFRelease(self.reachabilityRef);
            self.reachabilityRef = NULL;
        }
        self.isMonitoring = NO;
    });
}

- (BOOL)isReachable {
    return self.currentReachabilityType != ReachabilityTypeNone && self.currentReachabilityType != ReachabilityTypeUnknown;
}

- (BOOL)isReachableViaWiFi {
    return self.currentReachabilityType == ReachabilityTypeWiFi;
}

- (BOOL)isReachableViaWWAN {
    return (self.currentReachabilityType == ReachabilityTypeWWAN2G ||
            self.currentReachabilityType == ReachabilityTypeWWAN3G ||
            self.currentReachabilityType == ReachabilityTypeWWAN4G);
}

- (NSString *)currentConnectionType {
    switch (self.currentReachabilityType) {
        case ReachabilityTypeWiFi:
            return @"WiFi";
        case ReachabilityTypeWWAN2G:
            return @"2G";
        case ReachabilityTypeWWAN3G:
            return @"3G";
        case ReachabilityTypeWWAN4G:
            return @"4G";
        case ReachabilityTypeUnknown:
        default:
            return @"Unknown";
    }
}

- (void)updateReachabilityStatus {
    if (!self.reachabilityRef) {
        return;
    }
    
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        [self updateReachabilityStatus:flags];
    }
}

- (void)updateReachabilityStatus:(SCNetworkReachabilityFlags)flags {
    ReachabilityType newType = [self reachabilityTypeForFlags:flags];
    
    if (newType != self.currentReachabilityType) {
        self.currentReachabilityType = newType;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityStatusChangedNotification
                                                                object:self
                                                              userInfo:@{kReachabilityStatusUserInfoKey: @(newType)}];
        });
        
        [self.logger debug:[NSString stringWithFormat:@"Reachability changed to: %ld", (long)newType]];
    }
}

- (ReachabilityType)reachabilityTypeForFlags:(SCNetworkReachabilityFlags)flags {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        return ReachabilityTypeNone;
    }
    
    ReachabilityType returnValue = ReachabilityTypeUnknown;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        returnValue = ReachabilityTypeWiFi;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) ||
         ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) &&
        ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)) {
        returnValue = ReachabilityTypeWiFi;
    }
    
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        returnValue = [self wwanReachabilityType];
    }
    
    return returnValue;
}

- (ReachabilityType)wwanReachabilityType {
#if TARGET_OS_SIMULATOR
    // Simulator fallback - assume 4G
    return ReachabilityTypeWWAN4G;
#else
    // For iOS 14.0+, we can't use the deprecated constants
    // Default to 4G for WWAN connections
    return ReachabilityTypeWWAN4G;
#endif
}

@end

NS_ASSUME_NONNULL_END 
