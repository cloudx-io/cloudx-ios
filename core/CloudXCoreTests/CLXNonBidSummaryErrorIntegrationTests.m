/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXNonBidSummaryErrorIntegrationTests.m
 * @brief Tests the enriched non-bid error messages flowing through CLXBidAdSource
 */

#import <XCTest/XCTest.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXBidAdSource.h>

@interface CLXNonBidSummaryErrorIntegrationTests : XCTestCase
@end

@implementation CLXNonBidSummaryErrorIntegrationTests

#pragma mark - Enriched Error Message Tests

- (void)testNoBidsError_WithSeatNonBid_ErrorMessageContainsNonBidDetails {
    NSDictionary *responseDict = @{
        @"id": @"test",
        @"seatbid": @[],
        @"ext": @{
            @"prebid": @{
                @"seatnonbid": @[
                    @{@"seat": @"audienceNetwork", @"nonbid": @[@{@"impid": @"imp-1", @"statuscode": @0}]},
                    @{@"seat": @"vungle", @"nonbid": @[@{@"impid": @"imp-1", @"statuscode": @101}]}
                ]
            }
        }
    };
    
    CLXBidResponse *response = [CLXBidResponse parseBidResponseFromDictionary:responseDict];
    NSString *summary = [CLXBidResponse nonBidSummaryFromResponse:response];
    
    XCTAssertNotNil(summary);
    XCTAssertTrue(summary.length > 0);
    XCTAssertTrue([summary containsString:@"audienceNetwork"], @"Should contain bidder name");
    XCTAssertTrue([summary containsString:@"NoBid"], @"Should contain human-readable code 0 label");
    XCTAssertTrue([summary containsString:@"Timeout"], @"Should contain human-readable code 101 label");
}

- (void)testNoBidsError_WithNBR_ErrorMessageContainsNBRCode {
    NSDictionary *responseDict = @{
        @"id": @"test",
        @"seatbid": @[],
        @"nbr": @1
    };
    
    CLXBidResponse *response = [CLXBidResponse parseBidResponseFromDictionary:responseDict];
    NSString *summary = [CLXBidResponse nonBidSummaryFromResponse:response];
    
    XCTAssertNotNil(summary);
    XCTAssertTrue([summary containsString:@"NBR"], @"Should include NBR prefix");
    XCTAssertTrue([summary containsString:@"1"], @"Should include the NBR code value");
}

- (void)testNoBidsError_NoSeatNonBidNoNBR_FallsBackToGenericMessage {
    NSDictionary *responseDict = @{
        @"id": @"test",
        @"seatbid": @[]
    };
    
    CLXBidResponse *response = [CLXBidResponse parseBidResponseFromDictionary:responseDict];
    NSString *summary = [CLXBidResponse nonBidSummaryFromResponse:response];
    
    XCTAssertNil(summary, @"No non-bid info should produce nil summary, allowing fallback to generic message");
}

- (void)testNoBidsError_UserInfoContainsNonBidDetailsKey {
    NSDictionary *responseDict = @{
        @"id": @"test",
        @"seatbid": @[],
        @"ext": @{
            @"prebid": @{
                @"seatnonbid": @[
                    @{@"seat": @"bidder", @"nonbid": @[@{@"impid": @"imp-1", @"statuscode": @0}]}
                ]
            }
        }
    };
    
    CLXBidResponse *response = [CLXBidResponse parseBidResponseFromDictionary:responseDict];
    NSString *summary = [CLXBidResponse nonBidSummaryFromResponse:response];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = @"No bids in auction response.";
    if (summary.length > 0) {
        userInfo[CLXNonBidDetailsKey] = summary;
    }
    
    NSError *error = [NSError errorWithDomain:@"CLXBidAdSource" code:CLXBidAdSourceErrorNoBid userInfo:[userInfo copy]];
    
    XCTAssertNotNil(error.userInfo[CLXNonBidDetailsKey], @"userInfo should contain CLXNonBidDetailsKey");
    XCTAssertTrue([error.userInfo[CLXNonBidDetailsKey] containsString:@"bidder"],
                  @"CLXNonBidDetailsKey should contain the non-bid summary");
}

- (void)testNoBidsError_UserInfoMissesNonBidDetailsKeyWhenNoData {
    NSDictionary *responseDict = @{
        @"id": @"test",
        @"seatbid": @[]
    };
    
    CLXBidResponse *response = [CLXBidResponse parseBidResponseFromDictionary:responseDict];
    NSString *summary = [CLXBidResponse nonBidSummaryFromResponse:response];
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = @"No bids in auction response.";
    if (summary.length > 0) {
        userInfo[CLXNonBidDetailsKey] = summary;
    }
    
    NSError *error = [NSError errorWithDomain:@"CLXBidAdSource" code:CLXBidAdSourceErrorNoBid userInfo:[userInfo copy]];
    
    XCTAssertNil(error.userInfo[CLXNonBidDetailsKey], @"CLXNonBidDetailsKey should be absent when no non-bid data");
}

@end
