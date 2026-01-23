//
//  CLXVASTParser.m
//  CloudXRenderer
//
//  VAST 4.0 compliant video ad parser implementation
//
//  SURGICAL FIX: The previous implementation incorrectly reported "Linear creative 
//  found outside of InLine/Wrapper" when the Linear element WAS correctly nested.
//  
//  Per VAST 4.0 spec, the correct structure is:
//    VAST → Ad → InLine → Creatives → Creative → Linear
//  
//  This implementation properly traverses the XML tree to find Linear creatives.
//

#import "CLXVASTParser.h"
#import <CloudXCore/CLXLogger.h>

#pragma mark - Model Implementations

@implementation CLXVASTMediaFile
@end

@implementation CLXVASTTracking
@end

@implementation CLXVASTCreative
- (instancetype)init {
    self = [super init];
    if (self) {
        _mediaFiles = @[];
        _trackingEvents = @[];
        _clickTrackingURLs = @[];
        _impressionURLs = @[];
        _errorURLs = @[];
    }
    return self;
}
@end

@implementation CLXVASTAd
- (instancetype)init {
    self = [super init];
    if (self) {
        _creatives = @[];
        _impressionURLs = @[];
        _errorURLs = @[];
    }
    return self;
}
@end

@implementation CLXVASTDocument
- (instancetype)init {
    self = [super init];
    if (self) {
        _ads = @[];
        _wrapperURLs = @[];
    }
    return self;
}
@end

#pragma mark - Parser Implementation

@interface CLXVASTParser () <NSXMLParserDelegate>

@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) CLXVASTDocument *document;
@property (nonatomic, strong) CLXVASTAd *currentAd;
@property (nonatomic, strong) CLXVASTCreative *currentCreative;
@property (nonatomic, strong) CLXVASTMediaFile *currentMediaFile;
@property (nonatomic, strong) CLXVASTTracking *currentTracking;

// Element path tracking for proper nesting validation
@property (nonatomic, strong) NSMutableArray<NSString *> *elementPath;
@property (nonatomic, strong) NSMutableString *currentElementContent;

// Temporary storage during parsing
@property (nonatomic, strong) NSMutableArray<CLXVASTAd *> *parsedAds;
@property (nonatomic, strong) NSMutableArray<CLXVASTCreative *> *currentCreatives;
@property (nonatomic, strong) NSMutableArray<CLXVASTMediaFile *> *currentMediaFiles;
@property (nonatomic, strong) NSMutableArray<CLXVASTTracking *> *currentTrackingEvents;
@property (nonatomic, strong) NSMutableArray<NSURL *> *currentImpressionURLs;
@property (nonatomic, strong) NSMutableArray<NSURL *> *currentErrorURLs;
@property (nonatomic, strong) NSMutableArray<NSURL *> *currentClickTrackingURLs;

// State flags
@property (nonatomic, assign) BOOL isInInLine;
@property (nonatomic, assign) BOOL isInWrapper;
@property (nonatomic, assign) BOOL isInCreatives;
@property (nonatomic, assign) BOOL isInCreative;
@property (nonatomic, assign) BOOL isInLinear;
@property (nonatomic, assign) BOOL isInMediaFiles;
@property (nonatomic, assign) BOOL isInTrackingEvents;
@property (nonatomic, assign) BOOL isInVideoClicks;

@end

@implementation CLXVASTParser

+ (void)parseVASTString:(NSString *)vastXML
             completion:(void (^)(CLXVASTDocument * _Nullable, NSError * _Nullable))completion {
    
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXVASTParser"];
    
    if (!vastXML || vastXML.length == 0) {
        [logger error:@"[VAST] Cannot parse - XML string is empty"];
        NSError *error = [NSError errorWithDomain:@"CLXVASTParser" 
                                             code:100 
                                         userInfo:@{NSLocalizedDescriptionKey: @"VAST XML is empty"}];
        if (completion) completion(nil, error);
        return;
    }
    
    [logger info:[NSString stringWithFormat:@"[VAST] Parsing started (%lu bytes)", (unsigned long)vastXML.length]];
    
    NSData *xmlData = [vastXML dataUsingEncoding:NSUTF8StringEncoding];
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
    
    CLXVASTParser *vastParser = [[CLXVASTParser alloc] init];
    vastParser.logger = logger;
    
    xmlParser.delegate = vastParser;
    
    BOOL parseSuccess = [xmlParser parse];
    
    if (parseSuccess && vastParser.document) {
        // Validate that we found at least one Linear creative
        BOOL foundLinear = NO;
        for (CLXVASTAd *ad in vastParser.document.ads) {
            for (CLXVASTCreative *creative in ad.creatives) {
                if (creative.type == CLXVASTCreativeTypeLinear && creative.mediaFiles.count > 0) {
                    foundLinear = YES;
                    break;
                }
            }
            if (foundLinear) break;
        }
        
        [logger info:[NSString stringWithFormat:@"[VAST] Parsing complete: version=%@, ads=%lu, linearFound=%@", 
                      vastParser.document.version, 
                      (unsigned long)vastParser.document.ads.count,
                      foundLinear ? @"YES" : @"NO"]];
        
        if (completion) completion(vastParser.document, nil);
    } else {
        NSError *parseError = xmlParser.parserError ?: [NSError errorWithDomain:@"CLXVASTParser" 
                                                                           code:101 
                                                                       userInfo:@{NSLocalizedDescriptionKey: @"Failed to parse VAST XML"}];
        [logger error:[NSString stringWithFormat:@"[VAST] Parse failed: %@", parseError.localizedDescription]];
        if (completion) completion(nil, parseError);
    }
}

+ (void)parseVASTFromURL:(NSURL *)vastURL
              completion:(void (^)(CLXVASTDocument * _Nullable, NSError * _Nullable))completion {
    
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXVASTParser"];
    [logger info:[NSString stringWithFormat:@"[VAST] Fetching from URL: %@", vastURL.absoluteString]];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:vastURL 
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            [logger error:[NSString stringWithFormat:@"[VAST] Network error: %@", error.localizedDescription]];
            if (completion) completion(nil, error);
            return;
        }
        
        NSString *vastXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self parseVASTString:vastXML completion:completion];
    }];
    
    [task resume];
}

+ (nullable CLXVASTMediaFile *)selectBestMediaFile:(NSArray<CLXVASTMediaFile *> *)mediaFiles
                                        targetSize:(CGSize)targetSize {
    if (!mediaFiles || mediaFiles.count == 0) {
        return nil;
    }
    
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXVASTParser"];
    
    // Filter for progressive MP4 files (most compatible on iOS)
    NSMutableArray<CLXVASTMediaFile *> *compatibleFiles = [NSMutableArray array];
    for (CLXVASTMediaFile *file in mediaFiles) {
        if ([file.mimeType isEqualToString:@"video/mp4"] && 
            [file.delivery isEqualToString:@"progressive"]) {
            [compatibleFiles addObject:file];
        }
    }
    
    // Fallback to any MP4 if no progressive found
    if (compatibleFiles.count == 0) {
        for (CLXVASTMediaFile *file in mediaFiles) {
            if ([file.mimeType isEqualToString:@"video/mp4"]) {
                [compatibleFiles addObject:file];
            }
        }
    }
    
    // Fallback to HLS if available
    if (compatibleFiles.count == 0) {
        for (CLXVASTMediaFile *file in mediaFiles) {
            if ([file.mimeType isEqualToString:@"application/x-mpegURL"]) {
                [compatibleFiles addObject:file];
            }
        }
    }
    
    // Final fallback to any file
    if (compatibleFiles.count == 0) {
        compatibleFiles = [mediaFiles mutableCopy];
    }
    
    // Select best resolution for target size
    CLXVASTMediaFile *bestFile = compatibleFiles.firstObject;
    CGFloat targetPixels = targetSize.width * targetSize.height;
    CGFloat bestDiff = CGFLOAT_MAX;
    
    for (CLXVASTMediaFile *file in compatibleFiles) {
        CGFloat filePixels = file.width * file.height;
        CGFloat diff = fabs(filePixels - targetPixels);
        
        // Prefer slightly larger files over smaller for quality
        if (filePixels >= targetPixels * 0.5 && diff < bestDiff) {
            bestDiff = diff;
            bestFile = file;
        }
    }
    
    [logger debug:[NSString stringWithFormat:@"[VAST] Selected media file: %ldx%ld, %ld kbps, %@", 
                   (long)bestFile.width, (long)bestFile.height, (long)bestFile.bitrate, bestFile.mimeType]];
    
    return bestFile;
}

+ (void)fireTrackingEvents:(NSArray<CLXVASTTracking *> *)trackings
                  forEvent:(CLXVASTTrackingEvent)event
                  progress:(CGFloat)progress {
    
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXVASTParser"];
    
    for (CLXVASTTracking *tracking in trackings) {
        if (tracking.event == event) {
            [logger debug:[NSString stringWithFormat:@"[VAST] Firing tracking: %@", tracking.url.absoluteString]];
            
            NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:tracking.url 
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    [logger warn:[NSString stringWithFormat:@"[VAST] Tracking failed: %@", error.localizedDescription]];
                }
            }];
            [task resume];
        }
    }
}

+ (void)fireImpressionTracking:(NSArray<NSURL *> *)impressionURLs {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXVASTParser"];
    
    for (NSURL *url in impressionURLs) {
        [logger debug:[NSString stringWithFormat:@"[VAST] Firing impression: %@", url.absoluteString]];
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url 
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                [logger warn:[NSString stringWithFormat:@"[VAST] Impression tracking failed: %@", error.localizedDescription]];
            }
        }];
        [task resume];
    }
}

+ (void)fireErrorTracking:(NSArray<NSURL *> *)errorURLs errorCode:(NSInteger)errorCode {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXVASTParser"];
    
    for (NSURL *url in errorURLs) {
        // Replace [ERRORCODE] macro
        NSString *urlString = [url.absoluteString stringByReplacingOccurrencesOfString:@"[ERRORCODE]" 
                                                                            withString:[NSString stringWithFormat:@"%ld", (long)errorCode]];
        NSURL *finalURL = [NSURL URLWithString:urlString];
        
        [logger debug:[NSString stringWithFormat:@"[VAST] Firing error (%ld): %@", (long)errorCode, finalURL.absoluteString]];
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:finalURL 
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // Error tracking is best-effort
        }];
        [task resume];
    }
}

#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.document = [[CLXVASTDocument alloc] init];
    self.parsedAds = [NSMutableArray array];
    self.elementPath = [NSMutableArray array];
    self.currentElementContent = [NSMutableString string];
    
    // Reset all state flags
    self.isInInLine = NO;
    self.isInWrapper = NO;
    self.isInCreatives = NO;
    self.isInCreative = NO;
    self.isInLinear = NO;
    self.isInMediaFiles = NO;
    self.isInTrackingEvents = NO;
    self.isInVideoClicks = NO;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
    attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    
    [self.elementPath addObject:elementName];
    [self.currentElementContent setString:@""];
    
    // VAST root element
    if ([elementName isEqualToString:@"VAST"]) {
        self.document.version = attributeDict[@"version"] ?: @"unknown";
        [self.logger debug:[NSString stringWithFormat:@"[VAST] Version: %@", self.document.version]];
    }
    
    // Ad element
    else if ([elementName isEqualToString:@"Ad"]) {
        self.currentAd = [[CLXVASTAd alloc] init];
        self.currentAd.identifier = attributeDict[@"id"];
        self.currentCreatives = [NSMutableArray array];
        self.currentImpressionURLs = [NSMutableArray array];
        self.currentErrorURLs = [NSMutableArray array];
        [self.logger debug:[NSString stringWithFormat:@"[VAST] Found Ad: id=%@", self.currentAd.identifier]];
    }
    
    // InLine element (direct ad content)
    else if ([elementName isEqualToString:@"InLine"]) {
        self.isInInLine = YES;
        [self.logger info:[NSString stringWithFormat:@"[VAST] Found InLine ad: id=%@", self.currentAd.identifier]];
    }
    
    // Wrapper element (redirect to another VAST)
    else if ([elementName isEqualToString:@"Wrapper"]) {
        self.isInWrapper = YES;
        [self.logger info:@"[VAST] Found Wrapper ad"];
    }
    
    // Creatives container
    else if ([elementName isEqualToString:@"Creatives"]) {
        self.isInCreatives = YES;
    }
    
    // Individual Creative element
    else if ([elementName isEqualToString:@"Creative"]) {
        // SURGICAL FIX: Only process Creative if we're inside InLine/Creatives or Wrapper/Creatives
        if (self.isInCreatives && (self.isInInLine || self.isInWrapper)) {
            self.isInCreative = YES;
            self.currentCreative = [[CLXVASTCreative alloc] init];
            self.currentCreative.identifier = attributeDict[@"id"] ?: attributeDict[@"adId"];
            self.currentMediaFiles = [NSMutableArray array];
            self.currentTrackingEvents = [NSMutableArray array];
            self.currentClickTrackingURLs = [NSMutableArray array];
            [self.logger debug:[NSString stringWithFormat:@"[VAST] Found Creative: id=%@", self.currentCreative.identifier]];
        }
    }
    
    // Linear creative (video ad) - SURGICAL FIX: Only process if inside Creative
    else if ([elementName isEqualToString:@"Linear"]) {
        if (self.isInCreative) {
            self.isInLinear = YES;
            self.currentCreative.type = CLXVASTCreativeTypeLinear;
            
            // Parse skipoffset
            NSString *skipoffset = attributeDict[@"skipoffset"];
            if (skipoffset) {
                self.currentCreative.skipOffset = [self parseTimeOffset:skipoffset];
            }
            
            [self.logger debug:[NSString stringWithFormat:@"[VAST] Found Linear creative inside Creative (skipoffset=%@)", skipoffset ?: @"none"]];
        } else {
            // Log but don't error - this might be valid in some edge cases
            [self.logger warn:@"[VAST] Linear element found outside of Creative context - skipping"];
        }
    }
    
    // NonLinear creative
    else if ([elementName isEqualToString:@"NonLinear"] || [elementName isEqualToString:@"NonLinearAds"]) {
        if (self.isInCreative) {
            self.currentCreative.type = CLXVASTCreativeTypeNonLinear;
        }
    }
    
    // CompanionAds
    else if ([elementName isEqualToString:@"CompanionAds"]) {
        if (self.isInCreative) {
            self.currentCreative.type = CLXVASTCreativeTypeCompanionAds;
        }
    }
    
    // MediaFiles container
    else if ([elementName isEqualToString:@"MediaFiles"]) {
        if (self.isInLinear) {
            self.isInMediaFiles = YES;
        }
    }
    
    // Individual MediaFile
    else if ([elementName isEqualToString:@"MediaFile"]) {
        if (self.isInMediaFiles) {
            self.currentMediaFile = [[CLXVASTMediaFile alloc] init];
            self.currentMediaFile.mimeType = attributeDict[@"type"];
            self.currentMediaFile.width = [attributeDict[@"width"] integerValue];
            self.currentMediaFile.height = [attributeDict[@"height"] integerValue];
            self.currentMediaFile.bitrate = [attributeDict[@"bitrate"] integerValue];
            self.currentMediaFile.delivery = attributeDict[@"delivery"];
            self.currentMediaFile.scalable = [attributeDict[@"scalable"] boolValue];
            self.currentMediaFile.maintainAspectRatio = [attributeDict[@"maintainAspectRatio"] boolValue];
        }
    }
    
    // TrackingEvents container
    else if ([elementName isEqualToString:@"TrackingEvents"]) {
        if (self.isInLinear) {
            self.isInTrackingEvents = YES;
        }
    }
    
    // Individual Tracking event
    else if ([elementName isEqualToString:@"Tracking"]) {
        if (self.isInTrackingEvents) {
            self.currentTracking = [[CLXVASTTracking alloc] init];
            self.currentTracking.event = [self trackingEventFromString:attributeDict[@"event"]];
            
            NSString *offset = attributeDict[@"offset"];
            if (offset) {
                self.currentTracking.offset = [self parseTimeOffset:offset];
            }
        }
    }
    
    // VideoClicks container
    else if ([elementName isEqualToString:@"VideoClicks"]) {
        if (self.isInLinear) {
            self.isInVideoClicks = YES;
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    [self.currentElementContent appendString:string];
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    NSString *cdataString = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
    if (cdataString) {
        [self.currentElementContent appendString:cdataString];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName {
    
    NSString *content = [self.currentElementContent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Ad element complete
    if ([elementName isEqualToString:@"Ad"]) {
        if (self.currentAd) {
            self.currentAd.creatives = [self.currentCreatives copy];
            self.currentAd.impressionURLs = [self.currentImpressionURLs copy];
            self.currentAd.errorURLs = [self.currentErrorURLs copy];
            [self.parsedAds addObject:self.currentAd];
            self.currentAd = nil;
        }
    }
    
    // InLine complete
    else if ([elementName isEqualToString:@"InLine"]) {
        self.isInInLine = NO;
    }
    
    // Wrapper complete
    else if ([elementName isEqualToString:@"Wrapper"]) {
        self.isInWrapper = NO;
    }
    
    // Creatives complete
    else if ([elementName isEqualToString:@"Creatives"]) {
        self.isInCreatives = NO;
    }
    
    // Creative complete
    else if ([elementName isEqualToString:@"Creative"]) {
        if (self.isInCreative && self.currentCreative) {
            self.currentCreative.mediaFiles = [self.currentMediaFiles copy];
            self.currentCreative.trackingEvents = [self.currentTrackingEvents copy];
            self.currentCreative.clickTrackingURLs = [self.currentClickTrackingURLs copy];
            [self.currentCreatives addObject:self.currentCreative];
            
            [self.logger debug:[NSString stringWithFormat:@"[VAST] Creative complete: type=%ld, mediaFiles=%lu", 
                                (long)self.currentCreative.type, 
                                (unsigned long)self.currentCreative.mediaFiles.count]];
            
            self.currentCreative = nil;
        }
        self.isInCreative = NO;
    }
    
    // Linear complete
    else if ([elementName isEqualToString:@"Linear"]) {
        self.isInLinear = NO;
    }
    
    // MediaFiles complete
    else if ([elementName isEqualToString:@"MediaFiles"]) {
        self.isInMediaFiles = NO;
    }
    
    // MediaFile URL
    else if ([elementName isEqualToString:@"MediaFile"]) {
        if (self.currentMediaFile && content.length > 0) {
            self.currentMediaFile.url = [NSURL URLWithString:content];
            if (self.currentMediaFile.url) {
                [self.currentMediaFiles addObject:self.currentMediaFile];
            }
            self.currentMediaFile = nil;
        }
    }
    
    // TrackingEvents complete
    else if ([elementName isEqualToString:@"TrackingEvents"]) {
        self.isInTrackingEvents = NO;
    }
    
    // Tracking URL
    else if ([elementName isEqualToString:@"Tracking"]) {
        if (self.currentTracking && content.length > 0) {
            self.currentTracking.url = [NSURL URLWithString:content];
            if (self.currentTracking.url) {
                [self.currentTrackingEvents addObject:self.currentTracking];
            }
            self.currentTracking = nil;
        }
    }
    
    // VideoClicks complete
    else if ([elementName isEqualToString:@"VideoClicks"]) {
        self.isInVideoClicks = NO;
    }
    
    // ClickThrough URL
    else if ([elementName isEqualToString:@"ClickThrough"]) {
        if (self.isInVideoClicks && content.length > 0) {
            self.currentCreative.clickThroughURL = [NSURL URLWithString:content];
        }
    }
    
    // ClickTracking URL
    else if ([elementName isEqualToString:@"ClickTracking"]) {
        if (self.isInVideoClicks && content.length > 0) {
            NSURL *url = [NSURL URLWithString:content];
            if (url) {
                [self.currentClickTrackingURLs addObject:url];
            }
        }
    }
    
    // Ad-level elements
    else if ([elementName isEqualToString:@"AdTitle"]) {
        self.currentAd.title = content;
    }
    else if ([elementName isEqualToString:@"Description"]) {
        self.currentAd.description = content;
    }
    else if ([elementName isEqualToString:@"Advertiser"]) {
        self.currentAd.advertiser = content;
    }
    else if ([elementName isEqualToString:@"Impression"]) {
        if (content.length > 0) {
            NSURL *url = [NSURL URLWithString:content];
            if (url) {
                [self.currentImpressionURLs addObject:url];
            }
        }
    }
    else if ([elementName isEqualToString:@"Error"]) {
        if (content.length > 0) {
            NSURL *url = [NSURL URLWithString:content];
            if (url) {
                [self.currentErrorURLs addObject:url];
            }
        }
    }
    
    // Duration
    else if ([elementName isEqualToString:@"Duration"]) {
        if (self.isInLinear && content.length > 0) {
            self.currentCreative.duration = [self parseTimeOffset:content];
        }
    }
    
    // Pop element from path
    if (self.elementPath.count > 0) {
        [self.elementPath removeLastObject];
    }
    
    // Clear content for next element
    [self.currentElementContent setString:@""];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    self.document.ads = [self.parsedAds copy];
    
    // Calculate total duration
    NSTimeInterval totalDuration = 0;
    for (CLXVASTAd *ad in self.document.ads) {
        for (CLXVASTCreative *creative in ad.creatives) {
            if (creative.type == CLXVASTCreativeTypeLinear) {
                totalDuration += creative.duration;
            }
        }
    }
    self.document.totalDuration = totalDuration;
    
    [self.logger debug:[NSString stringWithFormat:@"[VAST] Document complete: %lu ads, %.1fs total duration", 
                        (unsigned long)self.document.ads.count, totalDuration]];
}

#pragma mark - Helper Methods

- (NSTimeInterval)parseTimeOffset:(NSString *)timeString {
    // Handle percentage format (e.g., "50%")
    if ([timeString hasSuffix:@"%"]) {
        return [[timeString stringByReplacingOccurrencesOfString:@"%" withString:@""] doubleValue] / 100.0;
    }
    
    // Handle HH:MM:SS format
    NSArray<NSString *> *components = [timeString componentsSeparatedByString:@":"];
    if (components.count == 3) {
        NSInteger hours = [components[0] integerValue];
        NSInteger minutes = [components[1] integerValue];
        double seconds = [components[2] doubleValue];
        return (hours * 3600) + (minutes * 60) + seconds;
    }
    
    // Handle plain seconds
    return [timeString doubleValue];
}

- (CLXVASTTrackingEvent)trackingEventFromString:(NSString *)eventString {
    static NSDictionary<NSString *, NSNumber *> *eventMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        eventMap = @{
            @"start": @(CLXVASTTrackingEventStart),
            @"firstQuartile": @(CLXVASTTrackingEventFirstQuartile),
            @"midpoint": @(CLXVASTTrackingEventMidpoint),
            @"thirdQuartile": @(CLXVASTTrackingEventThirdQuartile),
            @"complete": @(CLXVASTTrackingEventComplete),
            @"mute": @(CLXVASTTrackingEventMute),
            @"unmute": @(CLXVASTTrackingEventUnmute),
            @"pause": @(CLXVASTTrackingEventPause),
            @"resume": @(CLXVASTTrackingEventResume),
            @"rewind": @(CLXVASTTrackingEventRewind),
            @"skip": @(CLXVASTTrackingEventSkip),
            @"playerExpand": @(CLXVASTTrackingEventPlayerExpand),
            @"playerCollapse": @(CLXVASTTrackingEventPlayerCollapse),
            @"fullscreen": @(CLXVASTTrackingEventFullscreen),
            @"exitFullscreen": @(CLXVASTTrackingEventExitFullscreen),
        };
    });
    
    NSNumber *event = eventMap[eventString];
    return event ? [event integerValue] : CLXVASTTrackingEventStart;
}

@end
