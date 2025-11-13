//
//  CLXVASTParser.h
//  CloudXPrebidAdapter
//
//  VAST 4.0 compliant video ad parser
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * VAST creative types
 */
typedef NS_ENUM(NSInteger, CLXVASTCreativeType) {
    CLXVASTCreativeTypeLinear,
    CLXVASTCreativeTypeNonLinear,
    CLXVASTCreativeTypeCompanionAds
};

/**
 * Video tracking events
 */
typedef NS_ENUM(NSInteger, CLXVASTTrackingEvent) {
    CLXVASTTrackingEventStart,
    CLXVASTTrackingEventFirstQuartile,
    CLXVASTTrackingEventMidpoint,
    CLXVASTTrackingEventThirdQuartile,
    CLXVASTTrackingEventComplete,
    CLXVASTTrackingEventMute,
    CLXVASTTrackingEventUnmute,
    CLXVASTTrackingEventPause,
    CLXVASTTrackingEventResume,
    CLXVASTTrackingEventRewind,
    CLXVASTTrackingEventSkip,
    CLXVASTTrackingEventPlayerExpand,
    CLXVASTTrackingEventPlayerCollapse,
    CLXVASTTrackingEventFullscreen,
    CLXVASTTrackingEventExitFullscreen
};

/**
 * VAST media file information
 */
@interface CLXVASTMediaFile : NSObject
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger bitrate;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong) NSString *delivery;
@property (nonatomic, assign) BOOL scalable;
@property (nonatomic, assign) BOOL maintainAspectRatio;
@end

/**
 * VAST tracking URL
 */
@interface CLXVASTTracking : NSObject
@property (nonatomic, assign) CLXVASTTrackingEvent event;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) NSTimeInterval offset;
@end

/**
 * VAST creative information
 */
@interface CLXVASTCreative : NSObject
@property (nonatomic, assign) CLXVASTCreativeType type;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, assign) NSTimeInterval skipOffset;
@property (nonatomic, strong) NSArray<CLXVASTMediaFile *> *mediaFiles;
@property (nonatomic, strong) NSArray<CLXVASTTracking *> *trackingEvents;
@property (nonatomic, strong) NSURL *clickThroughURL;
@property (nonatomic, strong) NSArray<NSURL *> *clickTrackingURLs;
@property (nonatomic, strong) NSArray<NSURL *> *impressionURLs;
@property (nonatomic, strong) NSArray<NSURL *> *errorURLs;
@end

/**
 * VAST ad information
 */
@interface CLXVASTAd : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *advertiser;
@property (nonatomic, strong) NSArray<CLXVASTCreative *> *creatives;
@property (nonatomic, strong) NSArray<NSURL *> *impressionURLs;
@property (nonatomic, strong) NSArray<NSURL *> *errorURLs;
@end

/**
 * VAST document parser result
 */
@interface CLXVASTDocument : NSObject
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSArray<CLXVASTAd *> *ads;
@property (nonatomic, strong) NSArray<NSURL *> *wrapperURLs;
@property (nonatomic, assign) NSTimeInterval totalDuration;
@end

/**
 * VAST 4.0 compliant parser
 */
@interface CLXVASTParser : NSObject

/**
 * Parse VAST XML string
 * @param vastXML VAST XML content
 * @param completion Completion handler with parsed result or error
 */
+ (void)parseVASTString:(NSString *)vastXML
             completion:(void (^)(CLXVASTDocument *_Nullable document, NSError *_Nullable error))completion;

/**
 * Parse VAST from URL (handles wrappers and redirects)
 * @param vastURL URL to VAST XML
 * @param completion Completion handler with parsed result or error
 */
+ (void)parseVASTFromURL:(NSURL *)vastURL
              completion:(void (^)(CLXVASTDocument *_Nullable document, NSError *_Nullable error))completion;

/**
 * Get best media file for device capabilities
 * @param mediaFiles Array of available media files
 * @param targetSize Desired video size
 * @return Best matching media file
 */
+ (nullable CLXVASTMediaFile *)selectBestMediaFile:(NSArray<CLXVASTMediaFile *> *)mediaFiles
                                        targetSize:(CGSize)targetSize;

/**
 * Fire tracking URLs for specific event
 * @param trackings Array of tracking objects
 * @param event Event type to fire
 * @param progress Current playback progress (0.0-1.0)
 */
+ (void)fireTrackingEvents:(NSArray<CLXVASTTracking *> *)trackings
                  forEvent:(CLXVASTTrackingEvent)event
                  progress:(CGFloat)progress;

/**
 * Fire impression tracking URLs
 * @param impressionURLs Array of impression tracking URLs
 */
+ (void)fireImpressionTracking:(NSArray<NSURL *> *)impressionURLs;

/**
 * Fire error tracking URLs
 * @param errorURLs Array of error tracking URLs
 * @param errorCode VAST error code
 */
+ (void)fireErrorTracking:(NSArray<NSURL *> *)errorURLs errorCode:(NSInteger)errorCode;

@end

NS_ASSUME_NONNULL_END