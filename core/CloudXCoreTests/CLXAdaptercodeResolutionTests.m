/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXAdaptercodeResolutionTests.m
 * @brief Tests for adaptercode resolution priority chain, parsing, and marshalling round-trip
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXBidResponse.h>

@interface CLXAdaptercodeResolutionTests : XCTestCase
@end

@implementation CLXAdaptercodeResolutionTests

#pragma mark - resolveAdapterCodeFromExt: Priority Chain

- (void)testResolve_CloudXAdaptercode_TakesPriority {
    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    ext.cloudx.adaptercode = @"MetaAudienceNetwork";
    ext.prebid = [[CLXBidResponsePrebid alloc] init];
    ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    ext.prebid.meta.adaptercode = @"LegacyMeta";

    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:ext];
    XCTAssertEqualObjects(resolved, @"MetaAudienceNetwork", @"ext.cloudx.adaptercode should take priority over ext.prebid.meta");
}

- (void)testResolve_PrebidMetaFallback_WhenCloudXMissing {
    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    ext.prebid = [[CLXBidResponsePrebid alloc] init];
    ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    ext.prebid.meta.adaptercode = @"LegacyVungle";

    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:ext];
    XCTAssertEqualObjects(resolved, @"LegacyVungle", @"Should fall back to ext.prebid.meta.adaptercode");
}

- (void)testResolve_AdapterExtrasBidderFallback {
    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    ext.cloudx.adapterExtras = @{@"bidder": @"InMobi", @"adapter": @"ShouldNotUseThis"};

    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:ext];
    XCTAssertEqualObjects(resolved, @"InMobi", @"Should fall back to adapterExtras bidder before adapter");
}

- (void)testResolve_AdapterExtrasAdapterFallback {
    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    ext.cloudx.adapterExtras = @{@"adapter": @"Mintegral"};

    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:ext];
    XCTAssertEqualObjects(resolved, @"Mintegral", @"Should fall back to adapterExtras adapter when bidder is absent");
}

- (void)testResolve_NilExt_ReturnsNil {
    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:nil];
    XCTAssertNil(resolved, @"Should return nil for nil ext");
}

- (void)testResolve_EmptyExt_ReturnsNil {
    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:ext];
    XCTAssertNil(resolved, @"Should return nil when no adaptercode source exists");
}

- (void)testResolve_CloudXPresentButNoAdaptercode_FallsThrough {
    CLXBidResponseExt *ext = [[CLXBidResponseExt alloc] init];
    ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    ext.prebid = [[CLXBidResponsePrebid alloc] init];
    ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    ext.prebid.meta.adaptercode = @"FallbackAdapter";

    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:ext];
    XCTAssertEqualObjects(resolved, @"FallbackAdapter",
                          @"Should fall through to prebid.meta when cloudx exists but has no adaptercode");
}

#pragma mark - Parsing: ext.cloudx.adaptercode

- (void)testParsing_CloudXAdaptercode_ParsedCorrectly {
    NSDictionary *bidDict = @{
        @"id": @"bid-1",
        @"price": @2.50,
        @"ext": @{
            @"cloudx": @{
                @"rank": @1,
                @"revenue": @2.50,
                @"adaptercode": @"MetaAudienceNetwork"
            }
        }
    };

    CLXBidResponseBid *bid = [CLXBidResponse parseBidFromDictionary:bidDict];
    XCTAssertNotNil(bid);
    XCTAssertEqualObjects(bid.ext.cloudx.adaptercode, @"MetaAudienceNetwork");
}

- (void)testParsing_CloudXAdaptercode_IgnoresNonString {
    NSDictionary *bidDict = @{
        @"id": @"bid-1",
        @"price": @2.50,
        @"ext": @{
            @"cloudx": @{
                @"adaptercode": @42
            }
        }
    };

    CLXBidResponseBid *bid = [CLXBidResponse parseBidFromDictionary:bidDict];
    XCTAssertNotNil(bid);
    XCTAssertNil(bid.ext.cloudx.adaptercode, @"Non-string adaptercode should be ignored");
}

- (void)testParsing_PrebidMetaAdaptercode_StillParsed {
    NSDictionary *bidDict = @{
        @"id": @"bid-1",
        @"price": @1.00,
        @"ext": @{
            @"prebid": @{
                @"meta": @{
                    @"adaptercode": @"LegacyAdapter"
                }
            }
        }
    };

    CLXBidResponseBid *bid = [CLXBidResponse parseBidFromDictionary:bidDict];
    XCTAssertNotNil(bid);
    XCTAssertEqualObjects(bid.ext.prebid.meta.adaptercode, @"LegacyAdapter");
}

#pragma mark - Marshalling Round-Trip

- (void)testMarshalRoundTrip_CloudXAdaptercode_Preserved {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"bid-rt";
    bid.price = 3.00;
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.cloudx = [[CLXBidResponseCloudX alloc] init];
    bid.ext.cloudx.adaptercode = @"Vungle";
    bid.ext.cloudx.revenue = 3.00;
    bid.ext.cloudx.rank = 1;

    NSDictionary *marshalled = [CLXBidResponse marshalBidToJSONDictionary:bid];
    XCTAssertNotNil(marshalled);

    NSDictionary *extDict = marshalled[@"ext"];
    XCTAssertNotNil(extDict);
    NSDictionary *cloudxDict = extDict[@"cloudx"];
    XCTAssertNotNil(cloudxDict);
    XCTAssertEqualObjects(cloudxDict[@"adaptercode"], @"Vungle",
                          @"adaptercode should survive marshal round-trip in ext.cloudx");
}

- (void)testMarshalRoundTrip_PrebidMetaAdaptercode_Preserved {
    CLXBidResponseBid *bid = [[CLXBidResponseBid alloc] init];
    bid.id = @"bid-rt2";
    bid.price = 1.50;
    bid.ext = [[CLXBidResponseExt alloc] init];
    bid.ext.prebid = [[CLXBidResponsePrebid alloc] init];
    bid.ext.prebid.meta = [[CLXBidResponseCloudXMeta alloc] init];
    bid.ext.prebid.meta.adaptercode = @"LegacyMeta";

    NSDictionary *marshalled = [CLXBidResponse marshalBidToJSONDictionary:bid];
    NSDictionary *prebidDict = marshalled[@"ext"][@"prebid"];
    XCTAssertNotNil(prebidDict);
    XCTAssertEqualObjects(prebidDict[@"meta"][@"adaptercode"], @"LegacyMeta",
                          @"adaptercode should survive marshal round-trip in ext.prebid.meta");
}

- (void)testMarshalRoundTrip_FullParseAndResolve {
    NSDictionary *bidDict = @{
        @"id": @"bid-full",
        @"price": @5.00,
        @"ext": @{
            @"cloudx": @{
                @"rank": @1,
                @"revenue": @5.00,
                @"adaptercode": @"MetaAudienceNetwork"
            },
            @"prebid": @{
                @"meta": @{
                    @"adaptercode": @"ShouldNotResolveToThis"
                }
            }
        }
    };

    CLXBidResponseBid *bid = [CLXBidResponse parseBidFromDictionary:bidDict];
    XCTAssertNotNil(bid);

    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:bid.ext];
    XCTAssertEqualObjects(resolved, @"MetaAudienceNetwork",
                          @"Full parse→resolve should respect priority chain");

    NSDictionary *marshalled = [CLXBidResponse marshalBidToJSONDictionary:bid];
    CLXBidResponseBid *reparsed = [CLXBidResponse parseBidFromDictionary:marshalled];
    NSString *resolvedAgain = [CLXBidResponse resolveAdapterCodeFromExt:reparsed.ext];
    XCTAssertEqualObjects(resolvedAgain, @"MetaAudienceNetwork",
                          @"parse→marshal→reparse→resolve should be stable");
}

#pragma mark - Backward Compatibility

- (void)testBackwardCompat_OnlyPrebidMeta_ResolvesCorrectly {
    NSDictionary *bidDict = @{
        @"id": @"bid-legacy",
        @"price": @1.00,
        @"ext": @{
            @"prebid": @{
                @"meta": @{
                    @"adaptercode": @"Vungle"
                }
            },
            @"cloudx": @{
                @"rank": @1,
                @"revenue": @1.00
            }
        }
    };

    CLXBidResponseBid *bid = [CLXBidResponse parseBidFromDictionary:bidDict];
    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:bid.ext];
    XCTAssertEqualObjects(resolved, @"Vungle",
                          @"Older SSP responses with only ext.prebid.meta.adaptercode should still resolve");
}

- (void)testBackwardCompat_OnlyAdapterExtras_ResolvesCorrectly {
    NSDictionary *bidDict = @{
        @"id": @"bid-oldest",
        @"price": @0.50,
        @"ext": @{
            @"cloudx": @{
                @"rank": @1,
                @"revenue": @0.50,
                @"adapter_extras": @{
                    @"bidder": @"InMobi",
                    @"placement_id": @"123456"
                }
            }
        }
    };

    CLXBidResponseBid *bid = [CLXBidResponse parseBidFromDictionary:bidDict];
    NSString *resolved = [CLXBidResponse resolveAdapterCodeFromExt:bid.ext];
    XCTAssertEqualObjects(resolved, @"InMobi",
                          @"Oldest SSP responses with only adapterExtras should still resolve");
}

@end
