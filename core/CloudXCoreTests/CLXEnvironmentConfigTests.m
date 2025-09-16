#import <XCTest/XCTest.h>
#import <CloudXCore/CLXEnvironmentConfig.h>

@interface CLXEnvironmentConfigTests : XCTestCase
@property (nonatomic, strong) NSString *originalDebugEnvironment;
@end

@implementation CLXEnvironmentConfigTests

- (void)setUp {
    [super setUp];
    // Store original debug environment setting
    self.originalDebugEnvironment = [[NSUserDefaults standardUserDefaults] stringForKey:@"CLXDebugEnvironment"];
    // Clear any existing debug environment setting
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CLXDebugEnvironment"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)tearDown {
    // Restore original debug environment setting
    if (self.originalDebugEnvironment) {
        [[NSUserDefaults standardUserDefaults] setObject:self.originalDebugEnvironment forKey:@"CLXDebugEnvironment"];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"CLXDebugEnvironment"];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [super tearDown];
}

#pragma mark - Environment Selection Tests

- (void)testDefaultEnvironmentInDebugMode {
#ifdef DEBUG
    // Given: No debug environment preference set
    // When: Getting shared instance
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    
    // Then: Should default to development
    XCTAssertTrue(config.isDebugEnvironment, @"Should be debug environment");
    XCTAssertEqualObjects(config.environmentName, @"development", @"Should default to development environment");
    XCTAssertTrue([config.auctionEndpointURL containsString:@"au-dev.cloudx.io"], @"Should use dev auction URL");
    XCTAssertTrue([config.trackerRillBaseURL containsString:@"tracker-dev.cloudx.io"], @"Should use dev tracker URL");
#else
    // In production builds, should always use production
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    XCTAssertFalse(config.isDebugEnvironment, @"Should not be debug environment in production");
    XCTAssertEqualObjects(config.environmentName, @"production", @"Should use production environment");
#endif
}

- (void)testDebugEnvironmentSelection {
#ifdef DEBUG
    // Given: Setting debug environment to staging
    [CLXEnvironmentConfig setDebugEnvironment:@"staging"];
    
    // When: Getting shared instance (force re-initialization)
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    
    // Then: Should use staging environment
    XCTAssertTrue(config.isDebugEnvironment, @"Should be debug environment");
    XCTAssertEqualObjects(config.environmentName, @"staging", @"Should use staging environment");
    XCTAssertTrue([config.auctionEndpointURL containsString:@"au-stage.cloudx.io"], @"Should use staging auction URL");
    XCTAssertTrue([config.trackerRillBaseURL containsString:@"tracker-stage.cloudx.io"], @"Should use staging tracker URL");
#endif
}

- (void)testInvalidDebugEnvironmentIgnored {
#ifdef DEBUG
    // Given: Setting invalid debug environment
    [CLXEnvironmentConfig setDebugEnvironment:@"invalid"];
    
    // When: Getting shared instance
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    
    // Then: Should fall back to default (development)
    XCTAssertEqualObjects(config.environmentName, @"development", @"Should fall back to development for invalid environment");
#endif
}

#pragma mark - URL Construction Tests

- (void)testAuctionEndpointURL {
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    NSString *auctionURL = config.auctionEndpointURL;
    
    XCTAssertNotNil(auctionURL, @"Auction URL should not be nil");
    XCTAssertTrue([auctionURL hasPrefix:@"https://"], @"Auction URL should use HTTPS");
    XCTAssertTrue([auctionURL hasSuffix:@"/openrtb2/auction"], @"Auction URL should have correct path");
    XCTAssertTrue([auctionURL containsString:@"cloudx.io"], @"Auction URL should use cloudx.io domain");
}

- (void)testMetricsEndpointURL {
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    NSString *metricsURL = config.metricsEndpointURL;
    
    XCTAssertNotNil(metricsURL, @"Metrics URL should not be nil");
    XCTAssertTrue([metricsURL hasPrefix:@"https://ads.cloudx.io"], @"Metrics URL should use ads.cloudx.io");
    XCTAssertTrue([metricsURL containsString:@"/metrics"], @"Metrics URL should have metrics path");
    XCTAssertTrue([metricsURL containsString:@"?a=test"], @"Metrics URL should have default parameters");
}

- (void)testEventTrackingEndpointURL {
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    NSString *eventURL = config.eventTrackingEndpointURL;
    
    XCTAssertNotNil(eventURL, @"Event tracking URL should not be nil");
    XCTAssertTrue([eventURL hasPrefix:@"https://ads.cloudx.io"], @"Event URL should use ads.cloudx.io");
    XCTAssertTrue([eventURL containsString:@"/event"], @"Event URL should have event path");
    XCTAssertTrue([eventURL containsString:@"?a=test"], @"Event URL should have default parameters");
}

- (void)testTrackerBulkEndpointURL {
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    NSString *bulkURL = config.trackerBulkEndpointURL;
    
    XCTAssertNotNil(bulkURL, @"Bulk tracker URL should not be nil");
    XCTAssertTrue([bulkURL hasPrefix:@"https://"], @"Bulk tracker URL should use HTTPS");
    XCTAssertTrue([bulkURL containsString:@"tracker"], @"Bulk tracker URL should contain tracker");
    XCTAssertTrue([bulkURL containsString:@"cloudx.io"], @"Bulk tracker URL should use cloudx.io domain");
    XCTAssertTrue([bulkURL containsString:@"/t/bulk"], @"Bulk tracker URL should have correct path");
    
#ifdef DEBUG
    // In debug mode, should include debug parameter
    XCTAssertTrue([bulkURL containsString:@"debug=true"], @"Debug builds should include debug parameter");
#else
    // In production mode, should not include debug parameter
    XCTAssertFalse([bulkURL containsString:@"debug"], @"Production builds should not include debug parameter");
#endif
}

- (void)testTrackerRillBaseURL {
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    NSString *rillURL = config.trackerRillBaseURL;
    
    XCTAssertNotNil(rillURL, @"Rill tracker URL should not be nil");
    XCTAssertTrue([rillURL hasPrefix:@"https://"], @"Rill tracker URL should use HTTPS");
    XCTAssertTrue([rillURL containsString:@"tracker"], @"Rill tracker URL should contain tracker");
    XCTAssertTrue([rillURL containsString:@"cloudx.io"], @"Rill tracker URL should use cloudx.io domain");
    XCTAssertTrue([rillURL hasSuffix:@"/t/"], @"Rill tracker URL should end with /t/");
}

- (void)testInitializationEndpointURL {
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    NSString *initURL = config.initializationEndpointURL;
    
    XCTAssertNotNil(initURL, @"Initialization URL should not be nil");
    XCTAssertTrue([initURL hasPrefix:@"https://"], @"Initialization URL should use HTTPS");
    XCTAssertTrue([initURL containsString:@"pro"], @"Initialization URL should contain pro");
    XCTAssertTrue([initURL containsString:@"cloudx.io"], @"Initialization URL should use cloudx.io domain");
    XCTAssertTrue([initURL hasSuffix:@"/sdk"], @"Initialization URL should end with /sdk");
}

- (void)testGeoEndpointURL {
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    NSString *geoURL = config.geoEndpointURL;
    
    XCTAssertNotNil(geoURL, @"Geo URL should not be nil");
    XCTAssertTrue([geoURL hasPrefix:@"https://"], @"Geo URL should use HTTPS");
    XCTAssertTrue([geoURL containsString:@"geoip.cloudx.io"], @"Geo URL should use geoip.cloudx.io");
}

#pragma mark - Debug Environment API Tests

- (void)testAvailableDebugEnvironments {
    NSArray<NSString *> *environments = [CLXEnvironmentConfig availableDebugEnvironments];
    
#ifdef DEBUG
    XCTAssertEqual(environments.count, 2, @"Should have 2 debug environments available");
    XCTAssertTrue([environments containsObject:@"dev"], @"Should include dev environment");
    XCTAssertTrue([environments containsObject:@"staging"], @"Should include staging environment");
#else
    XCTAssertEqual(environments.count, 0, @"Production builds should have no debug environments");
#endif
}

- (void)testSetDebugEnvironmentPersistence {
#ifdef DEBUG
    // Given: Setting debug environment to staging
    [CLXEnvironmentConfig setDebugEnvironment:@"staging"];
    
    // When: Checking UserDefaults directly
    NSString *storedEnvironment = [[NSUserDefaults standardUserDefaults] stringForKey:@"CLXDebugEnvironment"];
    
    // Then: Should be persisted in UserDefaults
    XCTAssertEqualObjects(storedEnvironment, @"staging", @"Debug environment should be persisted in UserDefaults");
#endif
}

#pragma mark - Environment Consistency Tests

- (void)testEnvironmentConsistencyDev {
#ifdef DEBUG
    // Given: Setting to dev environment
    [CLXEnvironmentConfig setDebugEnvironment:@"dev"];
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    
    // Then: All URLs should use dev endpoints consistently
    XCTAssertTrue([config.auctionEndpointURL containsString:@"au-dev.cloudx.io"], @"Auction should use dev");
    XCTAssertTrue([config.trackerRillBaseURL containsString:@"tracker-dev.cloudx.io"], @"Tracker should use dev");
    XCTAssertTrue([config.initializationEndpointURL containsString:@"pro-dev.cloudx.io"], @"Init should use dev");
    
    // Metrics should always use ads.cloudx.io regardless of environment
    XCTAssertTrue([config.metricsEndpointURL containsString:@"ads.cloudx.io"], @"Metrics should always use ads.cloudx.io");
#endif
}

- (void)testEnvironmentConsistencyStaging {
#ifdef DEBUG
    // Given: Setting to staging environment
    [CLXEnvironmentConfig setDebugEnvironment:@"staging"];
    CLXEnvironmentConfig *config = [CLXEnvironmentConfig shared];
    
    // Then: All URLs should use staging endpoints consistently
    XCTAssertTrue([config.auctionEndpointURL containsString:@"au-stage.cloudx.io"], @"Auction should use staging");
    XCTAssertTrue([config.trackerRillBaseURL containsString:@"tracker-stage.cloudx.io"], @"Tracker should use staging");
    XCTAssertTrue([config.initializationEndpointURL containsString:@"pro-stage.cloudx.io"], @"Init should use staging");
    
    // Metrics should always use ads.cloudx.io regardless of environment
    XCTAssertTrue([config.metricsEndpointURL containsString:@"ads.cloudx.io"], @"Metrics should always use ads.cloudx.io");
#endif
}

@end
