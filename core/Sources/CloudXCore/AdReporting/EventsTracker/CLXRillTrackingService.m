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
#import <CloudXCore/CLXConfigImpressionModel.h>
#import <CloudXCore/CLXRillImpressionInitService.h>
#import <CloudXCore/CLXRillImpressionModel.h>
#import <CloudXCore/CLXTrackingFieldResolver.h>


@interface CLXRillTrackingService ()
@property (nonatomic, strong) id<CLXAdEventReporting> reportingService;
@property (nonatomic, copy) NSString *encodedString;
@property (nonatomic, copy) NSString *campaignId;
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXRillTrackingService

- (instancetype)initWithReportingService:(id<CLXAdEventReporting>)reportingService {
    self = [super init];
    if (self) {
        _reportingService = reportingService;
        _encodedString = @"";
        _campaignId = @"";
        _logger = [[CLXLogger alloc] initWithCategory:@"RillTracking"];
    }
    return self;
}



- (BOOL)setupTrackingDataFromBidResponse:(CLXBidAdSourceResponse *)bidResponse
                                impModel:(CLXConfigImpressionModel *)impModel
                             placementID:(NSString *)placementID
                               loadCount:(NSInteger)loadCount {
    if (!bidResponse || !impModel) {
        [self.logger debug:@"Missing bid response or impression model for Rill tracking"];
        return NO;
    }
    
    NSString *accountId = impModel.accountID;
    if (!accountId || accountId.length == 0) {
        [self.logger debug:@"No account ID available for Rill tracking"];
        return NO;
    }
    
    // Create Rill impression model using banner approach
    CLXRillImpressionModel *model = [[CLXRillImpressionModel alloc] initWithLastBidResponse:bidResponse 
                                                                                   impModel:impModel 
                                                                                adapterName:bidResponse.networkName 
                                                                      loadBannerTimesCount:loadCount 
                                                                                placementID:placementID];
    
    // Build tracking payload string
    NSString *payloadString = [CLXRillImpressionInitService createDataStringWithRillImpressionModel:model];
    if (!payloadString || payloadString.length == 0) {
        [self.logger debug:@"No payload string available for Rill tracking"];
        return NO;
    }
    
    // Generate encryption data
    NSData *secret = [CLXXorEncryption generateXorSecret:accountId];
    NSString *campaignId = [CLXXorEncryption generateCampaignIdBase64:accountId];
    NSString *encrypted = [CLXXorEncryption encrypt:payloadString secret:secret];
    
    // Store URL-encoded values for tracking calls
    _encodedString = [encrypted urlQueryEncodedString];
    _campaignId = [campaignId urlQueryEncodedString];
    
    [self.logger debug:[NSString stringWithFormat:@"Rill tracking data configured successfully - Campaign ID: %@", _campaignId]];
    
    // Send bid request tracking event
    [self sendBidRequestEvent];
    
    return YES;
}

- (void)sendBidRequestEvent {
    if (![self isReadyForTracking]) {
        [self.logger debug:@"Cannot send bid request event - tracking not configured"];
        return;
    }
    
    [self.reportingService rillTrackingWithActionString:@"bidreqenc" 
                                             campaignId:self.campaignId 
                                          encodedString:self.encodedString];
    [self.logger debug:@"Sent bid request Rill tracking event"];
}

- (void)sendImpressionEvent {
    if (![self isReadyForTracking]) {
        [self.logger debug:@"Cannot send impression event - tracking not configured"];
        return;
    }
    
    [self.reportingService rillTrackingWithActionString:@"sdkimpenc" 
                                             campaignId:self.campaignId 
                                          encodedString:self.encodedString];
    [self.logger debug:@"Sent impression Rill tracking event"];
}

- (void)sendClickEvent {
    if (![self isReadyForTracking]) {
        [self.logger debug:@"Cannot send click event - tracking not configured"];
        return;
    }
    
    [self.reportingService rillTrackingWithActionString:@"clickenc" 
                                             campaignId:self.campaignId 
                                          encodedString:self.encodedString];
    [self.logger debug:@"Sent click Rill tracking event"];
}

- (BOOL)isReadyForTracking {
    return self.encodedString.length > 0 && self.campaignId.length > 0 && self.reportingService != nil;
}

@end
