/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXPayloadBuilder.h"
#import <CloudXCore/CLXTrackingFieldResolver.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXSystemInformation.h>
#import <CloudXCore/CLXGeoLocationService.h>
#import <CloudXCore/CLXAdTrackingService.h>
#import <CloudXCore/CLXPrivacyService.h>
#import <UIKit/UIKit.h>

/**
 * Placeholder embedded in the base payload and replaced with actual UUIDs per event.
 */
static NSString * const kPlaceholderEventId = @"{eventId}";

@interface CLXPayloadBuilder ()

/**
 * The base payload template containing {eventId} placeholder.
 * Built once during initialization using TrackingFieldResolver.
 */
@property (nonatomic, copy) NSString *basePayload;

/**
 * The account ID, stored for encryption purposes.
 */
@property (nonatomic, copy, readwrite) NSString *accountId;

@property (nonatomic, strong) CLXLogger *logger;

@end

@implementation CLXPayloadBuilder

#pragma mark - Factory Method

+ (instancetype)createWithAccountId:(NSString *)accountId
              trackingFieldResolver:(CLXTrackingFieldResolver *)resolver {
    CLXPayloadBuilder *builder = [[CLXPayloadBuilder alloc] initPrivate];
    builder.accountId = accountId ?: @"";
    
    // Create a bid request JSON with device info for tracking field resolution
    // Required for bidRequest.device.model, bidRequest.device.os, bidRequest.device.osv, etc.
    UIDevice *device = [UIDevice currentDevice];
    NSString *model = [CLXSystemInformation shared].model ?: @"unknown";
    NSString *osVersion = device.systemVersion ?: @"unknown";
    // Get IFA and DNT for sdk.ifa field resolution
    // If privacy requires clearing personal data, use empty string for IFA
    BOOL piiRemove = [[CLXPrivacyService sharedInstance] shouldClearPersonalData];
    NSString *ifa = piiRemove ? @"" : ([CLXAdTrackingService idfa] ?: @"");
    NSNumber *dnt = @([CLXAdTrackingService dnt] ? 1 : 0);

    // Build geo dictionary from processedGeoData (mirrors Android PayloadBuilder)
    // Filter out reserved keys to prevent server-controlled mappings from re-introducing PII
    static NSSet *reservedGeoKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reservedGeoKeys = [NSSet setWithObjects:@"lat", @"lon", @"type", @"utcoffset", nil];
    });
    NSDictionary<NSString *, NSString *> *processedGeo = [[CLXGeoLocationService shared] processedGeoData];
    NSMutableDictionary *geoDict = [NSMutableDictionary dictionary];
    [processedGeo enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        if (![reservedGeoKeys containsObject:key]) {
            geoDict[key] = value;
        }
    }];
    
    NSDictionary *placeholderBidRequest = @{
        @"id": kPlaceholderEventId,
        @"device": @{
            @"model": model,
            @"os": @"iOS",
            @"osv": osVersion,
            @"geo": geoDict,
            @"ifa": ifa,
            @"dnt": dnt
        }
    };
    
    // Set the placeholder request data in the resolver for field resolution
    [resolver setRequestData:kPlaceholderEventId bidRequestJSON:placeholderBidRequest];
    
    // Build the base payload with {eventId} placeholder
    NSString *payload = [resolver buildPayload:kPlaceholderEventId];
    builder.basePayload = payload ?: @"";
    
    // PERMANENT: Log PayloadBuilder initialization at info level
    BOOL hasPlaceholder = [builder.basePayload containsString:kPlaceholderEventId];
    [builder.logger info:[NSString stringWithFormat:@"PayloadBuilder initialized: payloadLength=%lu, placeholderPresent=%@",
                          (unsigned long)builder.basePayload.length,
                          hasPlaceholder ? @"YES" : @"NO"]];
    
    // Warn if placeholder is missing - this would cause deduplication issues
    if (!hasPlaceholder && builder.basePayload.length > 0) {
        [builder.logger warn:@"PayloadBuilder basePayload missing {eventId} placeholder - metrics may be deduplicated!"];
    }
    
    return builder;
}

#pragma mark - Private Initializer

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _basePayload = @"";
        _accountId = @"";
        _logger = [[CLXLogger alloc] initWithCategory:@"PayloadBuilder"];
    }
    return self;
}

#pragma mark - Payload Building Methods

- (NSString *)buildMetricPayloadWithEventId:(NSString *)eventId
                                 metricName:(NSString *)metricName
                               metricDetail:(NSString *)metricDetail {
    // Replace placeholder with unique event ID and append metric name/detail
    NSString *payloadWithEventId = [self.basePayload stringByReplacingOccurrencesOfString:kPlaceholderEventId
                                                                               withString:eventId ?: @"unknown"];
    
    return [NSString stringWithFormat:@"%@;%@;%@",
            payloadWithEventId,
            metricName ?: @"",
            metricDetail ?: @""];
}

@end
