#import "LiveLogTextView.h"
#import "DemoAppLogger.h"

static NSUInteger const kLineLimit = 500;

@interface LiveLogTextView ()
@property (nonatomic, strong) NSMutableArray<NSString *> *lines;
@property (nonatomic, strong, nullable) id<NSObject> observer;
@end

@implementation LiveLogTextView

- (instancetype)initWithAccessibilityLabel:(NSString *)accessibilityLabel {
    self = [super initWithFrame:CGRectZero textContainer:nil];
    if (self) {
        _lines = [NSMutableArray array];
        self.accessibilityLabel = accessibilityLabel;
        self.editable = NO;
        self.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
        self.backgroundColor = [UIColor secondarySystemBackgroundColor];
        self.layer.cornerRadius = 8;

        __weak typeof(self) weakSelf = self;
        _observer = [[NSNotificationCenter defaultCenter] addObserverForName:DemoAppLoggerDidAppendEntryNotification
                                                                      object:nil
                                                                       queue:[NSOperationQueue mainQueue]
                                                                  usingBlock:^(NSNotification *notification) {
            DemoAppLogEntry *entry = notification.userInfo[DemoAppLoggerEntryUserInfoKey];
            if (![entry isKindOfClass:[DemoAppLogEntry class]]) return;
            [weakSelf appendLine:[NSString stringWithFormat:@"%@ %@", entry.formattedTimestamp, entry.message]];
        }];
    }
    return self;
}

- (void)dealloc {
    if (_observer) [[NSNotificationCenter defaultCenter] removeObserver:_observer];
}

- (void)appendLine:(NSString *)line {
    [self.lines addObject:line];
    if (self.lines.count > kLineLimit) {
        [self.lines removeObjectsInRange:NSMakeRange(0, self.lines.count - kLineLimit)];
    }
    self.text = [self.lines componentsJoinedByString:@"\n"];
    [self scrollRangeToVisible:NSMakeRange(self.text.length, 0)];
}

@end
