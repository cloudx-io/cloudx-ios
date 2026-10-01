#import "FirstLookInterstitialController.h"

NSString *NSStringFromFirstLookSource(FirstLookSource source) {
    switch (source) {
        case FirstLookSourceCloudX: return @"CLOUDX";
        case FirstLookSourceAdMob: return @"ADMOB";
        case FirstLookSourceNone: return @"NONE";
    }
    return @"NONE";
}

@interface FirstLookEvent ()
@property (nonatomic, readwrite) FirstLookEventType type;
@property (nonatomic, readwrite) FirstLookSource source;
@property (nonatomic, copy, readwrite, nullable) NSString *message;
@end

@implementation FirstLookEvent

+ (instancetype)eventWithType:(FirstLookEventType)type
                       source:(FirstLookSource)source
                      message:(nullable NSString *)message {
    FirstLookEvent *event = [[FirstLookEvent alloc] init];
    event.type = type;
    event.source = source;
    event.message = message;
    return event;
}

@end

@interface FirstLookInterstitialController ()
@property (nonatomic, strong, nullable) id<FirstLookInterstitialSource> cloudX;
@property (nonatomic, strong) id<FirstLookInterstitialSource> adMob;
@property (nonatomic, copy) FirstLookEventHandler onEvent;
@property (nonatomic) FirstLookSource loading;
@property (nonatomic) FirstLookSource showing;
@property (nonatomic) BOOL disposed;
@end

@implementation FirstLookInterstitialController

- (instancetype)initWithCloudX:(nullable id<FirstLookInterstitialSource>)cloudX
                         adMob:(id<FirstLookInterstitialSource>)adMob
                       onEvent:(FirstLookEventHandler)onEvent {
    self = [super init];
    if (self) {
        _cloudX = cloudX;
        _adMob = adMob;
        _onEvent = [onEvent copy];
        _loading = FirstLookSourceNone;
        _showing = FirstLookSourceNone;
        __weak typeof(self) weakSelf = self;
        FirstLookEventHandler handler = ^(FirstLookEvent *event) {
            [weakSelf handleEvent:event];
        };
        cloudX.onEvent = handler;
        adMob.onEvent = handler;
    }
    return self;
}

- (FirstLookSource)readySource {
    if (self.disposed || self.showing != FirstLookSourceNone) return FirstLookSourceNone;
    if (self.cloudX.isReady) return FirstLookSourceCloudX;
    if (self.adMob.isReady) return FirstLookSourceAdMob;
    return FirstLookSourceNone;
}

- (void)load {
    if (self.disposed || self.showing != FirstLookSourceNone || self.loading != FirstLookSourceNone
        || self.readySource != FirstLookSourceNone) {
        return;
    }

    if (self.cloudX) {
        self.loading = FirstLookSourceCloudX;
        [self.cloudX load];
    } else {
        [self loadAdMob];
    }
}

- (FirstLookSource)show {
    FirstLookSource source = self.readySource;
    if (source == FirstLookSourceNone) return FirstLookSourceNone;
    self.showing = source;
    switch (source) {
        case FirstLookSourceCloudX: [self.cloudX show]; break;
        case FirstLookSourceAdMob: [self.adMob show]; break;
        case FirstLookSourceNone: break;
    }
    return source;
}

- (void)dispose {
    if (self.disposed) return;
    self.disposed = YES;
    self.cloudX.onEvent = nil;
    self.adMob.onEvent = nil;
    [self.cloudX dispose];
    [self.adMob dispose];
}

- (void)loadAdMob {
    if (self.disposed || self.adMob.isReady) return;
    self.loading = FirstLookSourceAdMob;
    [self.adMob load];
}

- (void)handleEvent:(FirstLookEvent *)event {
    if (self.disposed) return;

    switch (event.type) {
        case FirstLookEventTypeLoaded:
            if (self.loading != event.source) return;
            self.loading = FirstLookSourceNone;
            self.onEvent(event);
            break;
        case FirstLookEventTypeLoadFailed:
            if (self.loading != event.source) return;
            self.loading = FirstLookSourceNone;
            if (event.source == FirstLookSourceCloudX) {
                [self loadAdMob];
            } else {
                self.onEvent(event);
            }
            break;
        case FirstLookEventTypeShowFailed:
            if (self.showing != event.source) return;
            if (event.source == FirstLookSourceCloudX && self.adMob.isReady) {
                self.showing = FirstLookSourceAdMob;
                [self.adMob show];
            } else {
                self.showing = FirstLookSourceNone;
                self.onEvent(event);
            }
            break;
        case FirstLookEventTypeClosed:
            if (self.showing != event.source) return;
            self.showing = FirstLookSourceNone;
            self.onEvent(event);
            break;
        case FirstLookEventTypeShown:
        case FirstLookEventTypeClicked:
            if (self.showing == event.source) self.onEvent(event);
            break;
    }
}

@end
