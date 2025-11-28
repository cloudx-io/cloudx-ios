/*
 * Copyright (c) 2025 CloudX. All rights reserved.
 */

/**
 * @file CLXEndpointResolver.m
 * @brief Implementation of endpoint resolver with A/B testing support
 */

#import <CloudXCore/CLXEndpointResolver.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXEndpointResolver ()
@property (nonatomic, copy, readwrite) NSString *auctionEndpoint;
@property (nonatomic, copy, readwrite) NSString *geoEndpoint;
@property (nonatomic, copy, readwrite) NSString *testGroupName;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXEndpointResolver

- (instancetype)init {
    self = [super init];
    if (self) {
        _auctionEndpoint = @"";
        _geoEndpoint = @"";
        _testGroupName = @"";
        _logger = [[CLXLogger alloc] initWithCategory:@"EndpointResolver"];
    }
    return self;
}

- (void)resolveFromConfig:(CLXSDKConfigResponse *)config {
    // Generate random value between 0.0 and 1.0
    double randomValue = ((double)arc4random() / UINT32_MAX);
    [self resolveFromConfig:config randomValue:randomValue];
}

- (void)resolveFromConfig:(CLXSDKConfigResponse *)config randomValue:(double)randomValue {
    if (!config) {
        [self.logger error:@"Config is nil, cannot resolve endpoints"];
        return;
    }
    
    // Geo endpoint - no A/B testing
    self.geoEndpoint = config.geoDataEndpointURL ?: @"";
    
    // A/B test configs
    [self.logger debug:@"================"];
    [self.logger debug:[NSString stringWithFormat:@"Generated random value: %.4f", randomValue]];
    
    // Collect test cases from auction endpoint
    NSMutableArray<NSDictionary *> *testCases = [NSMutableArray array];
    
    // Check auction endpoint for test variants
    if (config.auctionEndpointURL) {
        id value = [config.auctionEndpointURL value];
        if ([value isKindOfClass:[CLXSDKConfigEndpointObject class]]) {
            CLXSDKConfigEndpointObject *endpointObj = (CLXSDKConfigEndpointObject *)value;
            if (endpointObj.test && endpointObj.test.count > 0) {
                CLXSDKConfigEndpointValue *firstVariant = endpointObj.test.firstObject;
                if (firstVariant.value.length > 0) {
                    [testCases addObject:@{
                        @"variant": firstVariant,
                        @"endpointObject": endpointObj,
                        @"name": @"auction"
                    }];
                }
            }
        }
    }
    
    if (testCases.count == 0) {
        [self.logger debug:@"No valid test variants found, using defaults"];
        [self assignDefaultsFromConfig:config];
        return;
    }
    
    // Select test variant based on cumulative ratio
    double cumulativeRatio = 0.0;
    NSDictionary *selectedTest = nil;
    
    for (NSDictionary *testCase in testCases) {
        CLXSDKConfigEndpointValue *variant = testCase[@"variant"];
        cumulativeRatio += variant.ratio;
        if (randomValue <= cumulativeRatio) {
            selectedTest = testCase;
            break;
        }
    }
    
    self.testGroupName = selectedTest ? [selectedTest[@"variant"] name] ?: @"" : @"";
    
    // Assign auction endpoint
    if (selectedTest && [selectedTest[@"name"] isEqualToString:@"auction"]) {
        CLXSDKConfigEndpointValue *variant = selectedTest[@"variant"];
        self.auctionEndpoint = variant.value.length > 0 ? variant.value : [self getDefaultAuctionEndpoint:config];
    } else {
        self.auctionEndpoint = [self getDefaultAuctionEndpoint:config];
    }
    
    [self logEndpoints];
}

- (void)reset {
    self.auctionEndpoint = @"";
    self.geoEndpoint = @"";
    self.testGroupName = @"";
}

#pragma mark - Private Methods

- (void)assignDefaultsFromConfig:(CLXSDKConfigResponse *)config {
    self.auctionEndpoint = [self getDefaultAuctionEndpoint:config];
    [self logEndpoints];
}

- (NSString *)getDefaultAuctionEndpoint:(CLXSDKConfigResponse *)config {
    if (!config.auctionEndpointURL) {
        return @"";
    }
    
    id value = [config.auctionEndpointURL value];
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    } else if ([value isKindOfClass:[CLXSDKConfigEndpointObject class]]) {
        CLXSDKConfigEndpointObject *obj = (CLXSDKConfigEndpointObject *)value;
        return obj.defaultKey ?: @"";
    }
    
    return @"";
}

- (void)logEndpoints {
    [self.logger debug:@"Resolved Endpoints:"];
    
    NSString *auctionPreview = self.auctionEndpoint.length > 50 ? 
        [NSString stringWithFormat:@"%@...", [self.auctionEndpoint substringToIndex:50]] : 
        self.auctionEndpoint;
    [self.logger debug:[NSString stringWithFormat:@"auction: %@", auctionPreview]];
    
    if (self.testGroupName.length > 0) {
        [self.logger debug:[NSString stringWithFormat:@"A/B Test Group: %@", self.testGroupName]];
    }
    
    [self.logger debug:@"================"];
}

@end

