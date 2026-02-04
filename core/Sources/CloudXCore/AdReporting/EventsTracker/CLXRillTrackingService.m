/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

/**
 * @file CLXRillTrackingService.m
 * @brief Centralized service for Rill analytics tracking across all ad formats
 */

#import <CloudXCore/CLXRillTrackingService.h>
#import <CloudXCore/CLXAdEventReporting.h>
#import <CloudXCore/CLXXorEncryption.h>
#import <CloudXCore/NSString+CLXSemicolon.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXBidAdSource.h>
#import <CloudXCore/CLXBidResponse.h>
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>


@interface CLXRillTrackingService ()
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, copy) NSString *auctionId;
@property (nonatomic, copy) NSString *bidId;
@property (nonatomic, copy) NSString *accountId;
@property (nonatomic, copy) NSString *campaignId;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXRillTrackingService

- (instancetype)initWithReportingService:(id<CLXAdEventReporting>)reportingService {
    self = [super init];
    if (self) {
        _reportingService = reportingService;
        _auctionId = @"";
        _bidId = @"";
        _accountId = @"";
        _campaignId = @"";
        _logger = [[CLXLogger alloc] initWithCategory:@"RillTracking"];
    }
    return self;
}



- (BOOL)setupTrackingDataFromBidResponse:(CLXBidAdSourceResponse *)bidResponse
                                impModel:(CLXConfigImpressionModel *)impModel
                                adUnitId:(NSString *)adUnitId
                               loadCount:(NSInteger)loadCount {
    if (!bidResponse || !impModel) {
        [self.logger debug:@"Missing bid response or impression model for Analytics tracking"];
        return NO;
    }

    NSString *accountId = impModel.accountID;
    if (!accountId || accountId.length == 0) {
        [self.logger debug:@"No account ID available for Analytics tracking"];
        return NO;
    }

    // Store data for building payloads at event time (not load time)
    // This allows placement/customData to be included when they're set at show time
    _accountId = accountId;
    _auctionId = bidResponse.auctionId ?: impModel.auctionID ?: @"";
    _bidId = [bidResponse.bid id] ?: @"";

    if (_auctionId.length == 0) {
        [self.logger debug:@"No auction ID available for Analytics tracking"];
        return NO;
    }

    // Generate campaign ID once (based on account ID, doesn't change)
    NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64:accountId];
    _campaignId = [campaignId clx_urlQueryEncodedString];

    // Set up session data in resolver (needed for payload building)
    CLXRillImpressionModel *model = [[CLXRillImpressionModel alloc] initWithLastBidResponse:bidResponse
                                                                                   impModel:impModel
                                                                                adapterName:bidResponse.networkName
                                                                      loadBannerTimesCount:loadCount
                                                                                   adUnitId:adUnitId];
    // Initialize resolver with session data (but don't build payload yet)
    [CLXRillImpressionInitService createDataStringWithRillImpressionModel:model];

    [self.logger debug:[NSString stringWithFormat:@"Analytics tracking data configured - Auction ID: %@, Campaign ID: %@", _auctionId, _campaignId]];

    // Send bid request tracking event (bid request doesn't need placement/customData)
    [self sendBidRequestEvent];

    return YES;
}

- (void)sendBidRequestEvent {
    if (![self isReadyForTracking]) {
        [self.logger debug:@"Cannot send bid request event - tracking not configured"];
        return;
    }

    NSString *encodedPayload = [self buildEncodedPayload];
    if (!encodedPayload) {
        [self.logger debug:@"Cannot send bid request event - payload build failed"];
        return;
    }

    [self.reportingService rillTrackingWithActionString:@"bidreqenc"
                                             campaignId:self.campaignId
                                          encodedString:encodedPayload];
    [self.logger debug:@"Sent bid request Analytics tracking event"];
}

- (void)sendImpressionEvent {
    if (![self isReadyForTracking]) {
        [self.logger debug:@"Cannot send impression event - tracking not configured"];
        return;
    }

    // Build payload NOW - placement/customData will be available in resolver
    NSString *encodedPayload = [self buildEncodedPayload];
    if (!encodedPayload) {
        [self.logger debug:@"Cannot send impression event - payload build failed"];
        return;
    }

    [self.reportingService rillTrackingWithActionString:@"sdkimpenc"
                                             campaignId:self.campaignId
                                          encodedString:encodedPayload];
    [self.logger debug:@"Sent impression Analytics tracking event"];
}

- (void)sendClickEvent {
    if (![self isReadyForTracking]) {
        [self.logger debug:@"Cannot send click event - tracking not configured"];
        return;
    }

    // Build payload NOW - placement/customData will be available in resolver
    NSString *encodedPayload = [self buildEncodedPayload];
    if (!encodedPayload) {
        [self.logger debug:@"Cannot send click event - payload build failed"];
        return;
    }

    [self.reportingService rillTrackingWithActionString:@"clickenc"
                                             campaignId:self.campaignId
                                          encodedString:encodedPayload];
    [self.logger debug:@"Sent click Analytics tracking event"];
}

- (BOOL)isReadyForTracking {
    return self.auctionId.length > 0 && self.accountId.length > 0 && self.campaignId.length > 0 && self.reportingService != nil;
}

#pragma mark - Private Methods

- (NSString *)buildEncodedPayload {
    // Build payload fresh using CLXTrackingFieldResolver
    // This captures current state of sdk.placement and sdk.customData
    CLXTrackingFieldResolver *resolver = [CLXTrackingFieldResolver shared];
    NSString *payloadString = [resolver buildPayload:self.auctionId bidId:self.bidId];

    if (!payloadString || payloadString.length == 0) {
        [self.logger debug:@"Failed to build tracking payload"];
        return nil;
    }

    // Encrypt and URL-encode the payload
    NSData *secret = [CLXXorEncryption generateXorSecret:self.accountId];
    NSString *encrypted = [CLXXorEncryption encrypt:payloadString secret:secret];
    return [encrypted clx_urlQueryEncodedString];
}

@end
