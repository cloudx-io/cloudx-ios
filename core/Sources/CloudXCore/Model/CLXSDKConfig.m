#import <CloudXCore/CLXSDKConfig.h>

@implementation CLXSDKConfig

@synthesize bidders = _bidders;

- (instancetype)init {
    self = [super init];
    if (self) {
        _appKey = nil;
        _isDebug = NO;
        _sessionID = nil;
        _accountID = nil;
        _bidders = nil;
        _placements = nil;
        _auctionEndpointURL = nil;
        _cdpEndpointURL = nil;
    }
    return self;
}

- (instancetype)initWithAppKey:(NSString *)appKey isDebug:(BOOL)isDebug {
    self = [super init];
    if (self) {
        _appKey = [appKey copy];
        _isDebug = isDebug;
        _sessionID = nil;
        _accountID = nil;
        _bidders = nil;
        _placements = nil;
        _auctionEndpointURL = nil;
        _cdpEndpointURL = nil;
    }
    return self;
}

@end

@implementation CLXSDKConfigImp

- (instancetype)init {
    self = [super init];
    if (self) {
        _id = @"";
    }
    return self;
}

@end

@implementation CLXSDKConfigBanner

- (instancetype)init {
    self = [super init];
    if (self) {
        _format = [NSArray array];
    }
    return self;
}

@end

@implementation CLXSDKConfigFormat

- (instancetype)initWithWidth:(NSInteger)width height:(NSInteger)height {
    self = [super init];
    if (self) {
        _w = width;
        _h = height;
    }
    return self;
}

@end

// Response implementations
@implementation CLXSDKConfigResponse

- (instancetype)init {
    self = [super init];
    if (self) {
        _preCacheSize = 0;
        _placements = [NSArray array];
        _bidders = [NSArray array];
        _seatbid = [NSArray array];
        _tracking = nil;  // Leave as nil until explicitly set from server response
    }
    return self;
}

@end

@implementation CLXSDKConfigSeatBid

- (instancetype)init {
    self = [super init];
    if (self) {
        _bid = [NSArray array];
        _seat = @"";
    }
    return self;
}

@end

@implementation CLXSDKConfigBid

- (instancetype)init {
    self = [super init];
    if (self) {
        _id = @"";
        _impid = @"";
        _price = 0.0;
        _adm = @"";
        _adid = @"";
        _adomain = [NSArray array];
        _crid = @"";
        _w = 0;
        _h = 0;
    }
    return self;
}

@end

@implementation CLXSDKConfigBidExt

- (instancetype)init {
    self = [super init];
    if (self) {
        _origbidcpm = 0.0;
        _origbidcur = @"";
    }
    return self;
}

@end

@implementation CLXSDKConfigCloudXExt

- (instancetype)init {
    self = [super init];
    if (self) {
        _rank = 0;
    }
    return self;
}

@end

@implementation CLXSDKConfigKeyValueObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _eids = @"";
        _appKeyValues = @"";
        _placementLoopIndex = @"";
        _userKeyValues = @"";
    }
    return self;
}

@end

@implementation CLXSDKConfigGeoBid

- (instancetype)init {
    self = [super init];
    if (self) {
        _source = @"";
        _target = @"";
    }
    return self;
}

@end

@implementation CLXSDKConfigMeta

- (instancetype)init {
    self = [super init];
    if (self) {
        _adaptercode = @"";
    }
    return self;
}

@end

@implementation CLXSDKConfigEndpointQuantumValue

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize with nil values
    }
    return self;
}

- (nullable id)value {
    if (self.endpointString) {
        return self.endpointString;
    }
    if (self.endpointObject) {
        return self.endpointObject;
    }
    return nil;
}

@end

@implementation CLXSDKConfigLineItem

- (instancetype)init {
    self = [super init];
    if (self) {
        _suffix = @"";
    }
    return self;
}

@end

@implementation CLXSDKConfigQuantumValue

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize with nil values
    }
    return self;
}

- (nullable id)value {
    if (self.targeting) {
        return self.targeting;
    }
    if (self.targetingStrategy) {
        return self.targetingStrategy;
    }
    return nil;
}

@end

@implementation CLXSDKConfigTargetingStrategy

- (instancetype)init {
    self = [super init];
    if (self) {
        _strategy = @"";
    }
    return self;
}

@end

@implementation CLXSDKConfigTargeting

- (instancetype)init {
    self = [super init];
    if (self) {
        _strategy = @"";
        _conditionsAnd = NO;
        _conditions = [NSArray array];
    }
    return self;
}

@end

@implementation CLXSDKConfigCondition

- (instancetype)init {
    self = [super init];
    if (self) {
        _whitelist = [NSArray array];
        _blacklist = [NSArray array];
        _conditionsAnd = NO;
    }
    return self;
}

@end 
