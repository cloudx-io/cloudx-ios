/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXDebugLogViewController.h"
#import <CloudXCore/CLXLogStore.h>
#import <CloudXCore/CLXLogEntry.h>
#import <CloudXCore/CLXLogger.h>
#import <MessageUI/MessageUI.h>
#import <compression.h>
#import <OSLog/OSLog.h>

typedef NS_ENUM(NSInteger, CLXLogSource) {
    CLXLogSourceCloudX = 0,   // CloudX SDK logs
    CLXLogSourceAdSDKs = 1,   // OS logs filtered for ad SDK keywords
    CLXLogSourceOSRaw = 2     // All OS logs unfiltered (except CloudX)
};

static const NSUInteger kLogsPerPage = 50;
static const NSUInteger kMaxOSConsoleLogs = 1000;  // Match SDK's 1000 limit

@interface CLXDebugLogViewController () <MFMailComposeViewControllerDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UISegmentedControl *sourcePicker;
@property (nonatomic, strong) UISegmentedControl *levelPicker;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *clipboardButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIActivityIndicatorView *loadingFooter;
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, assign) CLXLogLevel selectedLevel;
@property (nonatomic, assign) CLXLogSource selectedSource;
@property (nonatomic, strong) NSArray *cachedAdSdkLogs;
@property (nonatomic, strong) NSArray *cachedOSRawLogs;
@property (nonatomic, strong) NSDate *lastAdSdkLogFetch;
@property (nonatomic, strong) NSDate *lastOSRawFetch;
@property (nonatomic, assign) NSUInteger displayedLogCount;
@property (nonatomic, strong) NSArray *allFilteredEntries;  // Full list for pagination
@property (nonatomic, strong) UIView *shimmerView;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL isLoadingMore;
@property (nonatomic, assign) BOOL hasMoreLogs;

@end

@implementation CLXDebugLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selectedLevel = CLXLogLevelInfo; // Default to INFO
    self.selectedSource = CLXLogSourceCloudX; // Default to SDK logs
    self.displayedLogCount = kLogsPerPage;
    [self setupUI];
    [self refreshLogs];
    [self startAutoRefresh];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];
    
    // Drag handle area (invisible, for gesture only - iOS sheet already shows grabber)
    UIView *dragHandleArea = [[UIView alloc] init];
    dragHandleArea.backgroundColor = [UIColor clearColor];
    dragHandleArea.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:dragHandleArea];
    
    // Add pan gesture for drag to dismiss
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragToDismiss:)];
    [dragHandleArea addGestureRecognizer:panGesture];
    
    // Drag handle area constraints (just for gesture detection)
    [NSLayoutConstraint activateConstraints:@[
        [dragHandleArea.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [dragHandleArea.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [dragHandleArea.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [dragHandleArea.heightAnchor constraintEqualToConstant:30]
    ]];
    
    // Header stack
    UIStackView *headerStack = [[UIStackView alloc] init];
    headerStack.axis = UILayoutConstraintAxisHorizontal;
    headerStack.alignment = UIStackViewAlignmentCenter;
    headerStack.spacing = 8;
    headerStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:headerStack];
    
    // Header label
    self.headerLabel = [[UILabel alloc] init];
    self.headerLabel.text = @"🔍 CloudX Debug Logs";
    self.headerLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    self.headerLabel.textColor = [UIColor whiteColor];
    [headerStack addArrangedSubview:self.headerLabel];
    
    // Spacer
    UIView *spacer = [[UIView alloc] init];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [headerStack addArrangedSubview:spacer];
    
    // Close button
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        [self.closeButton setImage:[UIImage systemImageNamed:@"xmark"] forState:UIControlStateNormal];
    } else {
        [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    }
    self.closeButton.tintColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [headerStack addArrangedSubview:self.closeButton];
    
    // Source picker (CloudX | Ad SDKs | OS Raw)
    self.sourcePicker = [[UISegmentedControl alloc] initWithItems:@[@"CloudX", @"Ad SDKs", @"OS Raw"]];
    self.sourcePicker.selectedSegmentIndex = 0; // CloudX
    self.sourcePicker.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sourcePicker addTarget:self action:@selector(sourceChanged:) forControlEvents:UIControlEventValueChanged];
    if (@available(iOS 13.0, *)) {
        self.sourcePicker.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.2 alpha:1.0];
        self.sourcePicker.selectedSegmentTintColor = [UIColor colorWithRed:0.45 green:0.35 blue:0.55 alpha:1.0];  // Dark pastel purple
        [self.sourcePicker setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [self.sourcePicker setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    }
    [self.view addSubview:self.sourcePicker];
    
    // Level picker
    self.levelPicker = [[UISegmentedControl alloc] initWithItems:@[@"Verbose", @"Debug", @"Info", @"Warn", @"Error"]];
    self.levelPicker.selectedSegmentIndex = 2; // Info
    self.levelPicker.translatesAutoresizingMaskIntoConstraints = NO;
    [self.levelPicker addTarget:self action:@selector(levelChanged:) forControlEvents:UIControlEventValueChanged];
    if (@available(iOS 13.0, *)) {
        self.levelPicker.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.2 alpha:1.0];
        self.levelPicker.selectedSegmentTintColor = [UIColor colorWithRed:0.35 green:0.35 blue:0.38 alpha:1.0];  // Light dark gray
        [self.levelPicker setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [self.levelPicker setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    }
    [self.view addSubview:self.levelPicker];
    
    // Button stack
    UIStackView *buttonStack = [[UIStackView alloc] init];
    buttonStack.axis = UILayoutConstraintAxisHorizontal;
    buttonStack.spacing = 12;
    buttonStack.distribution = UIStackViewDistributionFillEqually;
    buttonStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:buttonStack];
    
    // Send button
    self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
    if (@available(iOS 13.0, *)) {
        UIImageConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium];
        [self.sendButton setImage:[UIImage systemImageNamed:@"paperplane.fill" withConfiguration:config] forState:UIControlStateNormal];
    }
    [self.sendButton setTitle:@" Send" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.sendButton.tintColor = [UIColor whiteColor];
    self.sendButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.sendButton addTarget:self action:@selector(emailTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.sendButton];
    
    // Copy button
    self.clipboardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clipboardButton setTitle:@"📋 Copy" forState:UIControlStateNormal];
    [self.clipboardButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.clipboardButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.clipboardButton addTarget:self action:@selector(copyTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.clipboardButton];
    
    // Clear button
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearButton setTitle:@"🗑 Clear" forState:UIControlStateNormal];
    [self.clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.clearButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.clearButton addTarget:self action:@selector(clearTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonStack addArrangedSubview:self.clearButton];
    
    // Text view for logs with scroll delegate for infinite scroll
    self.textView = [[UITextView alloc] init];
    self.textView.backgroundColor = [UIColor colorWithRed:0.12 green:0.14 blue:0.18 alpha:1.0];
    self.textView.textColor = [UIColor whiteColor];
    self.textView.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    self.textView.editable = NO;
    self.textView.delegate = self;
    self.textView.layer.cornerRadius = 12;
    self.textView.layer.borderWidth = 1;
    self.textView.layer.borderColor = [UIColor colorWithRed:0.2 green:0.22 blue:0.28 alpha:1.0].CGColor;
    self.textView.contentInset = UIEdgeInsetsMake(8, 4, 44, 4);  // Extra bottom for loading footer
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textView];
    
    // Loading footer (spinner shown when loading more)
    if (@available(iOS 13.0, *)) {
        self.loadingFooter = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    } else {
        self.loadingFooter = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    }
    self.loadingFooter.color = [UIColor colorWithRed:0.5 green:0.7 blue:1.0 alpha:1.0];
    self.loadingFooter.hidesWhenStopped = YES;
    self.loadingFooter.translatesAutoresizingMaskIntoConstraints = NO;
    [self.textView addSubview:self.loadingFooter];
    
    // Shimmer loading view (shown while loading logs)
    [self setupShimmerView];
    
    // Layout constraints
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [headerStack.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:12],
        [headerStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [headerStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        
        [self.closeButton.widthAnchor constraintEqualToConstant:36],
        [self.closeButton.heightAnchor constraintEqualToConstant:36],
        
        // Send/Copy/Clear buttons (compact)
        [buttonStack.topAnchor constraintEqualToAnchor:headerStack.bottomAnchor constant:12],
        [buttonStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [buttonStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [buttonStack.heightAnchor constraintEqualToConstant:32],
        
        // Source picker (SDK | Console | OS | All)
        [self.sourcePicker.topAnchor constraintEqualToAnchor:buttonStack.bottomAnchor constant:12],
        [self.sourcePicker.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.sourcePicker.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        
        // Log level picker
        [self.levelPicker.topAnchor constraintEqualToAnchor:self.sourcePicker.bottomAnchor constant:8],
        [self.levelPicker.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.levelPicker.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        
        // Logs text view (full height, no button below)
        [self.textView.topAnchor constraintEqualToAnchor:self.levelPicker.bottomAnchor constant:12],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.textView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-12]
    ]];
    
    // Update UI states
    [self updateLevelPickerState];
    [self updateClearButtonState];
}

#pragma mark - UIScrollViewDelegate (Infinite Scroll)

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Check if scrolled near bottom
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat frameHeight = scrollView.frame.size.height;
    
    // Trigger load more when within 100pt of bottom
    if (offsetY > contentHeight - frameHeight - 100) {
        [self loadMoreIfNeeded];
    }
    
    // Position the loading footer at the bottom of content
    if (self.loadingFooter.isAnimating) {
        CGFloat footerY = MAX(contentHeight, frameHeight) - 30;
        self.loadingFooter.center = CGPointMake(scrollView.bounds.size.width / 2, footerY);
    }
}

- (void)loadMoreIfNeeded {
    // Don't load if already loading or no more logs
    if (self.isLoadingMore || !self.hasMoreLogs) {
        return;
    }
    
    self.isLoadingMore = YES;
    self.displayedLogCount += kLogsPerPage;
    
    // Show loading footer
    [self showLoadingFooter];
    
    // Refresh logs (will hide footer when done)
    [self refreshLogs];
}

- (void)showLoadingFooter {
    // Position at bottom of content
    CGFloat footerY = MAX(self.textView.contentSize.height, self.textView.frame.size.height) - 30;
    self.loadingFooter.center = CGPointMake(self.textView.bounds.size.width / 2, footerY);
    [self.loadingFooter startAnimating];
}

- (void)hideLoadingFooter {
    [self.loadingFooter stopAnimating];
    self.isLoadingMore = NO;
}

#pragma mark - Shimmer Loading View

- (void)setupShimmerView {
    self.shimmerView = [[UIView alloc] init];
    self.shimmerView.backgroundColor = [UIColor colorWithRed:0.12 green:0.14 blue:0.18 alpha:1.0];
    self.shimmerView.layer.cornerRadius = 12;
    self.shimmerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.shimmerView.hidden = YES;
    [self.view addSubview:self.shimmerView];
    
    // Position shimmer over the text view
    [NSLayoutConstraint activateConstraints:@[
        [self.shimmerView.topAnchor constraintEqualToAnchor:self.textView.topAnchor],
        [self.shimmerView.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor],
        [self.shimmerView.trailingAnchor constraintEqualToAnchor:self.textView.trailingAnchor],
        [self.shimmerView.bottomAnchor constraintEqualToAnchor:self.textView.bottomAnchor]
    ]];
    
    // Add fake text lines with shimmer effect
    [self addShimmerLines];
}

- (void)addShimmerLines {
    // Create fake log lines
    CGFloat yOffset = 16;
    CGFloat lineHeight = 14;
    CGFloat lineSpacing = 8;
    
    for (int i = 0; i < 12; i++) {
        UIView *line = [[UIView alloc] init];
        line.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
        line.layer.cornerRadius = 3;
        line.translatesAutoresizingMaskIntoConstraints = NO;
        line.tag = 100 + i;  // For identification
        [self.shimmerView addSubview:line];
        
        // Vary line widths to look like real text
        CGFloat widthPercent = 0.5 + (arc4random_uniform(50) / 100.0);  // 50-100%
        
        [NSLayoutConstraint activateConstraints:@[
            [line.topAnchor constraintEqualToAnchor:self.shimmerView.topAnchor constant:yOffset],
            [line.leadingAnchor constraintEqualToAnchor:self.shimmerView.leadingAnchor constant:16],
            [line.widthAnchor constraintEqualToAnchor:self.shimmerView.widthAnchor multiplier:widthPercent constant:-32],
            [line.heightAnchor constraintEqualToConstant:lineHeight]
        ]];
        
        yOffset += lineHeight + lineSpacing;
    }
}

- (void)showShimmer {
    self.isLoading = YES;
    
    // Cancel any pending hide animation and reset state
    [self.shimmerView.layer removeAllAnimations];
    self.shimmerView.alpha = 1.0;
    self.shimmerView.hidden = NO;
    [self.view bringSubviewToFront:self.shimmerView];
    
    // Start shimmer animation
    [self startShimmerAnimation];
}

- (void)hideShimmer {
    self.isLoading = NO;
    
    // Stop animation and hide
    for (UIView *line in self.shimmerView.subviews) {
        [line.layer removeAllAnimations];
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        self.shimmerView.alpha = 0;
    } completion:^(BOOL finished) {
        self.shimmerView.hidden = YES;
        self.shimmerView.alpha = 1;
    }];
}

- (void)startShimmerAnimation {
    for (UIView *line in self.shimmerView.subviews) {
        // Stagger the animation start for each line
        CGFloat delay = (line.tag - 100) * 0.05;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self animateShimmerLine:line];
        });
    }
}

- (void)animateShimmerLine:(UIView *)line {
    if (self.shimmerView.hidden) return;
    
    // Pulse opacity animation
    [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
        line.alpha = 0.3;
    } completion:nil];
}

- (void)startAutoRefresh {
    [self.refreshTimer invalidate];
    
    // Only auto-refresh for SDK logs (OS logs are static and expensive to fetch)
    if (self.selectedSource == CLXLogSourceCloudX) {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            [self refreshLogs];
        }];
    }
}

- (void)stopAutoRefresh {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (CLXLogLevel)levelFromPickerIndex:(NSInteger)index {
    switch (index) {
        case 0: return CLXLogLevelVerbose;
        case 1: return CLXLogLevelDebug;
        case 2: return CLXLogLevelInfo;
        case 3: return CLXLogLevelWarn;
        case 4: return CLXLogLevelError;
        default: return CLXLogLevelInfo;
    }
}

- (void)levelChanged:(UISegmentedControl *)picker {
    self.selectedLevel = [self levelFromPickerIndex:picker.selectedSegmentIndex];
    
    // Scroll to top immediately
    [self.textView setContentOffset:CGPointZero animated:NO];
    
    [self refreshLogs];
}

- (void)sourceChanged:(UISegmentedControl *)picker {
    self.selectedSource = (CLXLogSource)picker.selectedSegmentIndex;
    // DON'T clear cached OS/Console logs - reuse them for faster switching
    self.displayedLogCount = kLogsPerPage; // Reset pagination
    self.hasMoreLogs = NO; // Reset until we know from refreshLogs
    self.isLoadingMore = NO;
    [self updateLevelPickerState];
    [self updateClearButtonState];
    [self startAutoRefresh]; // Restart (or stop) auto-refresh based on source
    
    // Scroll to top and clear old content immediately
    [self.textView setContentOffset:CGPointZero animated:NO];
    self.textView.text = @"";  // Clear old content before loading new
    
    // Show shimmer loading overlay
    [self showShimmer];
    
    // Force layout so shimmer is visible before refresh starts
    [self.view layoutIfNeeded];
    
    // Defer refresh slightly so shimmer has time to render
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshLogs];
    });
}

- (void)updateLevelPickerState {
    // Level picker only applies to CloudX SDK logs
    BOOL showsSDKLogs = (self.selectedSource == CLXLogSourceCloudX);
    self.levelPicker.enabled = showsSDKLogs;
    self.levelPicker.alpha = showsSDKLogs ? 1.0 : 0.4;
}

- (void)updateClearButtonState {
    // Clear button only works for SDK logs (can't clear system logs)
    BOOL canClear = (self.selectedSource == CLXLogSourceCloudX);
    self.clearButton.enabled = canClear;
    self.clearButton.alpha = canClear ? 1.0 : 0.4;
}

- (void)refreshLogs {
    // Capture current state for background processing
    CLXLogSource source = self.selectedSource;
    CLXLogLevel level = self.selectedLevel;
    NSUInteger maxToDisplay = self.displayedLogCount;
    
    // Do heavy work on background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *allDisplayEntries = [NSMutableArray array];
        
        // Get CloudX SDK logs
        if (source == CLXLogSourceCloudX) {
            CLXLogStore *logStore = [CLXLogStore shared];
            NSArray<CLXLogEntry *> *sdkEntries = [logStore allEntries];
            for (CLXLogEntry *entry in sdkEntries) {
                if (entry.level >= level) {
                    [allDisplayEntries addObject:@{
                        @"source": @"CloudX",
                        @"timestamp": entry.timestamp ?: [NSDate date],
                        @"message": [entry formattedString],
                        @"entry": entry
                    }];
                }
            }
        }
        
        // Get Ad SDK logs (OS logs filtered by ad keywords)
        if (source == CLXLogSourceAdSDKs) {
            NSArray *adLogs = [self fetchAdSdkLogs];  // This one has the keyword filter
            [allDisplayEntries addObjectsFromArray:adLogs];
        }
        
        // Get OS Raw logs (all OS logs except CloudX)
        if (source == CLXLogSourceOSRaw) {
            NSArray *osLogs = [self fetchOSRawLogs];  // This one is unfiltered except CloudX
            [allDisplayEntries addObjectsFromArray:osLogs];
        }
        
        // Sort by timestamp (newest first)
        [allDisplayEntries sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [b[@"timestamp"] compare:a[@"timestamp"]];
        }];
        
        // Store full list for pagination
        self.allFilteredEntries = [allDisplayEntries copy];
        
        // Limit to displayed count (pagination)
        NSUInteger totalCount = allDisplayEntries.count;
        NSUInteger displayCount = MIN(maxToDisplay, totalCount);
        NSArray *entriesToDisplay = [allDisplayEntries subarrayWithRange:NSMakeRange(0, displayCount)];
        BOOL hasMore = totalCount > displayCount;
        NSUInteger remaining = totalCount - displayCount;
        
        // Build attributed string
        NSMutableAttributedString *result = [self buildAttributedStringForEntries:entriesToDisplay 
                                                                           source:source
                                                                       totalCount:totalCount
                                                                          hasMore:hasMore
                                                                        remaining:remaining];
        
        // Update UI on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            // Hide shimmer loading and loading footer
            [self hideShimmer];
            [self hideLoadingFooter];
            
            self.hasMoreLogs = hasMore;
            
            if (totalCount == 0) {
                NSString *emptyMessage = [self emptyMessageForSource:source];
                self.textView.text = emptyMessage;
                self.textView.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
            } else {
                self.textView.attributedText = result;
            }
        });
    });
}

- (NSString *)emptyMessageForSource:(CLXLogSource)source {
    if (source == CLXLogSourceAdSDKs) {
        if (@available(iOS 15.0, *)) {
            return @"No Ad SDK logs found.\n\nShows OS logs filtered for ad networks.\n\nTry loading an ad to generate logs.";
        } else {
            return @"Ad SDK logs require iOS 15+.\n\nYour device is running an older iOS version.";
        }
    } else if (source == CLXLogSourceOSRaw) {
        if (@available(iOS 15.0, *)) {
            return @"No OS Raw logs found.\n\nShows all system logs except CloudX.\n\nTry loading an ad to generate logs.";
        } else {
            return @"OS Raw logs require iOS 15+.\n\nYour device is running an older iOS version.";
        }
    } else {
        return @"No logs captured yet.\n\nAd events will appear here.";
    }
}

- (NSMutableAttributedString *)buildAttributedStringForEntries:(NSArray *)entries
                                                        source:(CLXLogSource)source
                                                    totalCount:(NSUInteger)totalCount
                                                       hasMore:(BOOL)hasMore
                                                     remaining:(NSUInteger)remaining {
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] init];
    
    // CloudX SDK logs: white
    NSDictionary *cloudxAttrs = @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular]
    };
    
    // Ad SDK logs (filtered): yellow
    NSDictionary *adSdkAttrs = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:1.0 green:0.8 blue:0.4 alpha:1.0],
        NSFontAttributeName: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular]
    };
    
    // OS Raw logs (unfiltered): green
    NSDictionary *osRawAttrs = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.6 green:0.8 blue:0.5 alpha:1.0],
        NSFontAttributeName: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular]
    };
    
    NSDictionary *separatorAttrs = @{
        NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.3],
        NSFontAttributeName: [UIFont monospacedSystemFontOfSize:8 weight:UIFontWeightUltraLight]
    };
    
    NSDictionary *headerAttrs = @{
        NSForegroundColorAttributeName: [[UIColor whiteColor] colorWithAlphaComponent:0.7],
        NSFontAttributeName: [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular]
    };
    
    // Add each log with separator
    NSString *separator = @"─────────────────────────────────";
    for (NSUInteger i = 0; i < entries.count; i++) {
        NSDictionary *entry = entries[i];
        NSString *entrySource = entry[@"source"];
        NSString *message = entry[@"message"];
        
        NSDictionary *attrs = cloudxAttrs;
        if ([entrySource isEqualToString:@"AdSDK"]) {
            attrs = adSdkAttrs;
        } else if ([entrySource isEqualToString:@"OSRaw"]) {
            attrs = osRawAttrs;
        }
        [result appendAttributedString:[[NSAttributedString alloc] initWithString:message attributes:attrs]];
        
        if (i < entries.count - 1) {
            NSString *sepLine = [NSString stringWithFormat:@"\n%@\n", separator];
            [result appendAttributedString:[[NSAttributedString alloc] initWithString:sepLine attributes:separatorAttrs]];
        }
    }
    
    return result;
}

- (NSArray *)fetchAdSdkLogs {
    if (@available(iOS 15.0, *)) {
        // Cache OS logs for 30 seconds (they don't change fast, and fetching is slow)
        if (self.cachedAdSdkLogs && self.lastAdSdkLogFetch && 
            [[NSDate date] timeIntervalSinceDate:self.lastAdSdkLogFetch] < 30.0) {
            return self.cachedAdSdkLogs;
        }
        
        NSMutableArray *logs = [NSMutableArray array];
        
        @try {
            NSError *error = nil;
            OSLogStore *store = [OSLogStore storeWithScope:OSLogStoreCurrentProcessIdentifier error:&error];
            if (error || !store) {
                return @[];
            }
            
            // Get logs from last 5 minutes
            NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-300];
            OSLogPosition *position = [store positionWithDate:startDate];
            
            OSLogEnumeratorOptions options = 0;
            NSPredicate *predicate = nil;
            
            OSLogEnumerator *enumerator = [store entriesEnumeratorWithOptions:options
                                                                     position:position
                                                                    predicate:predicate
                                                                        error:&error];
            if (error || !enumerator) {
                return @[];
            }
            
            // Collect log entries
            OSLogEntryLog *entry;
            NSUInteger count = 0;
            NSUInteger maxLogs = kMaxOSConsoleLogs;
            
            while ((entry = [enumerator nextObject]) && count < maxLogs) {
                if (![entry isKindOfClass:[OSLogEntryLog class]]) {
                    continue;
                }
                
                // Filter for ad-related subsystems
                NSString *subsystem = entry.subsystem ?: @"";
                NSString *category = entry.category ?: @"";
                NSString *message = entry.composedMessage ?: @"";
                
                // EXCLUDE CloudX SDK logs first
                NSString *lowerSubsystem = subsystem.lowercaseString;
                BOOL isCloudXLog = [subsystem isEqualToString:@"io.cloudx.sdk"] ||
                                   [lowerSubsystem containsString:@"cloudx"] ||
                                   [message hasPrefix:@"[CloudX]"];
                if (isCloudXLog) {
                    continue;
                }
                
                // Look for ad SDK related logs - expanded keyword list
                BOOL isAdRelated = NO;
                NSArray *adKeywords = @[
                    // SDK names
                    @"vungle", @"facebook", @"meta", @"audience", @"admob", @"applovin", 
                    @"unityads", @"ironsource", @"chartboost", @"inmobi", @"mintegral",
                    @"pangle", @"bytedance", @"tapjoy", @"adcolony", @"digitalturbine",
                    @"fyber", @"smaato", @"amazon", @"criteo", @"verve", @"hybid",
                    @"ogury", @"mytarget", @"liftoff", @"magnite", @"moloco",
                    @"rubicon", @"spotx",
                    // Ad unit types
                    @"banner", @"interstitial", @"rewarded", @"mrec", @"native",
                    // Generic ad terms
                    @"adview", @"adrequest", @"adload", @"adfail", @"adshow"
                ];
                
                NSString *lowerCategory = category.lowercaseString;
                NSString *lowerMessage = message.lowercaseString;
                
                for (NSString *keyword in adKeywords) {
                    if ([lowerSubsystem containsString:keyword] || 
                        [lowerCategory containsString:keyword] ||
                        [lowerMessage containsString:keyword]) {
                        isAdRelated = YES;
                        break;
                    }
                }
                
                if (!isAdRelated) {
                    continue;
                }
                
                // Format the log entry
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"HH:mm:ss.SSS";
                NSString *timestamp = [formatter stringFromDate:entry.date];
                
                NSString *levelEmoji = @"📝";
                switch (entry.level) {
                    case OSLogEntryLogLevelDebug: levelEmoji = @"🔍"; break;
                    case OSLogEntryLogLevelInfo: levelEmoji = @"ℹ️"; break;
                    case OSLogEntryLogLevelNotice: levelEmoji = @"📢"; break;
                    case OSLogEntryLogLevelError: levelEmoji = @"❌"; break;
                    case OSLogEntryLogLevelFault: levelEmoji = @"💥"; break;
                    default: break;
                }
                
                NSString *formattedMessage = [NSString stringWithFormat:@"%@ [%@] %@\n   └─ %@:%@",
                    levelEmoji, timestamp, message, subsystem, category];
                
                [logs addObject:@{
                    @"source": @"AdSDK",
                    @"timestamp": entry.date,
                    @"message": formattedMessage
                }];
                
                count++;
            }
            
            self.cachedAdSdkLogs = logs;
            self.lastAdSdkLogFetch = [NSDate date];
            
        } @catch (NSException *exception) {
            return @[];
        }
        
        return logs;
    }
    
    return @[];
}

// Console logs: Higher-level logs that look like NSLog/print output
// These are typically what you'd see in Xcode console - cleaner than raw OS logs
- (NSArray *)fetchOSRawLogs {
    if (@available(iOS 15.0, *)) {
        // Cache console logs for 30 seconds
        if (self.cachedOSRawLogs && self.lastOSRawFetch && 
            [[NSDate date] timeIntervalSinceDate:self.lastOSRawFetch] < 30.0) {
            return self.cachedOSRawLogs;
        }
        
        NSMutableArray *logs = [NSMutableArray array];
        
        @try {
            NSError *error = nil;
            OSLogStore *store = [OSLogStore storeWithScope:OSLogStoreCurrentProcessIdentifier error:&error];
            if (error || !store) {
                return @[];
            }
            
            // Get logs from last 5 minutes
            NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-300];
            OSLogPosition *position = [store positionWithDate:startDate];
            
            OSLogEnumerator *enumerator = [store entriesEnumeratorWithOptions:0
                                                                     position:position
                                                                    predicate:nil
                                                                        error:&error];
            if (error || !enumerator) {
                return @[];
            }
            
            OSLogEntryLog *entry;
            NSUInteger count = 0;
            NSUInteger maxLogs = kMaxOSConsoleLogs;
            
            while ((entry = [enumerator nextObject]) && count < maxLogs) {
                if (![entry isKindOfClass:[OSLogEntryLog class]]) {
                    continue;
                }
                
                // Match Xcode console: only show Info level and above (not Debug/Verbose)
                // Xcode console doesn't show debug-level logs by default
                if (entry.level < OSLogEntryLogLevelInfo) {
                    continue;
                }
                
                NSString *subsystem = entry.subsystem ?: @"";
                NSString *message = entry.composedMessage ?: @"";
                
                // EXCLUDE CloudX SDK logs (show everything else)
                // CloudX uses subsystem "io.cloudx.sdk" and prefix "[CloudX]"
                BOOL isCloudXLog = [subsystem isEqualToString:@"io.cloudx.sdk"] ||
                                   [message hasPrefix:@"[CloudX]"];
                
                if (isCloudXLog) {
                    continue;
                }
                
                // Format the log entry (simpler than OS logs)
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"HH:mm:ss.SSS";
                NSString *timestamp = [formatter stringFromDate:entry.date];
                
                NSString *formattedMessage = [NSString stringWithFormat:@"[%@] %@", timestamp, message];
                
                [logs addObject:@{
                    @"source": @"OSRaw",
                    @"timestamp": entry.date,
                    @"message": formattedMessage
                }];
                
                count++;
            }
            
            // Cache the results
            self.cachedOSRawLogs = logs;
            self.lastOSRawFetch = [NSDate date];
            
        } @catch (NSException *exception) {
            return @[];
        }
        
        return logs;
    }
    
    return @[];
}

#pragma mark - Actions

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleDragToDismiss:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.view];
    CGPoint velocity = [gesture velocityInView:self.view];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateChanged: {
            // Only allow downward drag
            if (translation.y > 0) {
                self.view.transform = CGAffineTransformMakeTranslation(0, translation.y * 0.5);
                // Fade out as dragged down
                CGFloat progress = MIN(translation.y / 200.0, 1.0);
                self.view.alpha = 1.0 - (progress * 0.3);
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // Dismiss if dragged far enough or with enough velocity
            if (translation.y > 100 || velocity.y > 500) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                // Snap back
                [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
                    self.view.transform = CGAffineTransformIdentity;
                    self.view.alpha = 1.0;
                } completion:nil];
            }
            break;
        }
        default:
            break;
    }
}

- (void)clearTapped {
    [[CLXLogStore shared] clear];
    // Also clear cached OS logs
    self.cachedAdSdkLogs = nil;
    self.cachedOSRawLogs = nil;
    self.allFilteredEntries = nil;
    self.displayedLogCount = kLogsPerPage;
    self.hasMoreLogs = NO;
    
    // Update UI immediately (empty state)
    self.textView.text = @"Logs cleared.\n\nNew logs will appear here.";
    self.textView.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
}

- (void)copyTapped {
    // Copy from already-displayed text (no refetch needed)
    NSString *textToCopy = self.textView.text;
    if (!textToCopy || textToCopy.length == 0) {
        textToCopy = @"(No logs to copy)";
    }
    [UIPasteboard generalPasteboard].string = textToCopy;
    
    // Show feedback
    NSString *originalTitle = [self.clipboardButton titleForState:UIControlStateNormal];
    [self.clipboardButton setTitle:@"✓ Copied!" forState:UIControlStateNormal];
    [self.clipboardButton setTitleColor:[UIColor systemGreenColor] forState:UIControlStateNormal];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.clipboardButton setTitle:originalTitle forState:UIControlStateNormal];
        [self.clipboardButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    });
}

- (void)emailTapped {
    if (![MFMailComposeViewController canSendMail]) {
        [self showAlertWithTitle:@"Cannot Send Email" message:@"Mail is not configured on this device. Please set up a mail account in Settings."];
        return;
    }
    
    MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
    mailVC.mailComposeDelegate = self;
    
    // Hardcoded recipient
    [mailVC setToRecipients:@[@"bryan@cloudx.io"]];
    
    // Subject with app info
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ?: @"App";
    NSString *deviceName = [[UIDevice currentDevice] name];
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
    NSString *timestamp = [[NSISO8601DateFormatter new] stringFromDate:[NSDate date]];
    
    NSString *subject = [NSString stringWithFormat:@"🚨 [%@ DEBUG LOGS] %@ - v%@ - %@", appName.uppercaseString, deviceName, appVersion, timestamp];
    [mailVC setSubject:subject];
    
    // Body with device info
    NSString *body = [NSString stringWithFormat:
        @"CloudX SDK Debug Logs\n"
        @"=====================\n\n"
        @"Device: %@\n"
        @"Model: %@\n"
        @"iOS: %@\n"
        @"App Version: %@\n"
        @"Timestamp: %@\n\n"
        @"3 Attachments:\n"
        @"1. filtered-logs.txt - Currently displayed logs (per filter settings)\n"
        @"2. sdk-all-logs.txt - All SDK verbose logs\n"
        @"3. os-logs.txt - OS-level logs from ad SDKs\n\n"
        @"---\n"
        @"Sent from CloudX Debug Log Viewer",
        deviceName,
        [[UIDevice currentDevice] model],
        [[UIDevice currentDevice] systemVersion],
        appVersion,
        timestamp
    ];
    [mailVC setMessageBody:body isHTML:NO];
    
    NSString *ts = [self formattedTimestamp];
    
    // Attachment 1: Currently filtered logs
    NSString *filteredLogs = [self buildFilteredLogsExportString];
    NSData *filteredData = [filteredLogs dataUsingEncoding:NSUTF8StringEncoding];
    [mailVC addAttachmentData:filteredData mimeType:@"text/plain" fileName:[NSString stringWithFormat:@"filtered-logs-%@.txt", ts]];
    
    // Attachment 2: All SDK logs (verbose level)
    NSString *allSDKLogs = [self buildAllSDKLogsExportString];
    NSData *sdkData = [allSDKLogs dataUsingEncoding:NSUTF8StringEncoding];
    [mailVC addAttachmentData:sdkData mimeType:@"text/plain" fileName:[NSString stringWithFormat:@"sdk-all-logs-%@.txt", ts]];
    
    // Attachment 3: All OS logs
    NSString *allOSLogs = [self buildAllOSLogsExportString];
    NSData *osData = [allOSLogs dataUsingEncoding:NSUTF8StringEncoding];
    [mailVC addAttachmentData:osData mimeType:@"text/plain" fileName:[NSString stringWithFormat:@"os-logs-%@.txt", ts]];
    
    [self presentViewController:mailVC animated:YES completion:nil];
}

- (NSString *)buildFilteredLogsExportString {
    NSMutableString *result = [NSMutableString string];
    
    // Header with filter info
    NSString *sourceLabel = @"CloudX";
    if (self.selectedSource == CLXLogSourceAdSDKs) sourceLabel = @"Ad SDKs";
    else if (self.selectedSource == CLXLogSourceOSRaw) sourceLabel = @"OS Raw";
    
    NSString *levelLabel = @"Info";
    switch (self.selectedLevel) {
        case CLXLogLevelVerbose: levelLabel = @"Verbose"; break;
        case CLXLogLevelDebug: levelLabel = @"Debug"; break;
        case CLXLogLevelInfo: levelLabel = @"Info"; break;
        case CLXLogLevelWarn: levelLabel = @"Warn"; break;
        case CLXLogLevelError: levelLabel = @"Error"; break;
    }
    
    [result appendFormat:@"Filter: Source=%@, Level=%@+\n", sourceLabel, levelLabel];
    [result appendString:@"─────────────────────────────────\n\n"];
    
    // Get CloudX SDK logs
    if (self.selectedSource == CLXLogSourceCloudX) {
        CLXLogStore *logStore = [CLXLogStore shared];
        NSArray<CLXLogEntry *> *sdkEntries = [logStore allEntries];
        for (CLXLogEntry *entry in sdkEntries) {
            if (entry.level >= self.selectedLevel) {
                [result appendFormat:@"[CloudX] %@\n", [entry formattedString]];
            }
        }
    }
    
    // Get Ad SDK logs (filtered)
    if (self.selectedSource == CLXLogSourceAdSDKs) {
        NSArray *adLogs = [self fetchAdSdkLogs];
        for (NSDictionary *log in adLogs) {
            [result appendFormat:@"[Ad SDK] %@\n", log[@"message"]];
        }
    }
    
    // Get OS Raw logs (unfiltered)
    if (self.selectedSource == CLXLogSourceOSRaw) {
        NSArray *osLogs = [self fetchOSRawLogs];
        for (NSDictionary *log in osLogs) {
            [result appendFormat:@"[OS] %@\n", log[@"message"]];
        }
    }
    
    return result;
}

- (NSString *)buildAllSDKLogsExportString {
    NSMutableString *result = [NSMutableString string];
    
    [result appendString:@"CloudX SDK Logs (All Verbose+)\n"];
    [result appendString:@"─────────────────────────────────\n\n"];
    
    CLXLogStore *logStore = [CLXLogStore shared];
    NSArray<CLXLogEntry *> *sdkEntries = [logStore allEntries];
    for (CLXLogEntry *entry in sdkEntries) {
        [result appendFormat:@"%@\n", [entry formattedString]];
    }
    
    if (sdkEntries.count == 0) {
        [result appendString:@"(No SDK logs captured)\n"];
    }
    
    return result;
}

- (NSString *)buildAllOSLogsExportString {
    NSMutableString *result = [NSMutableString string];
    
    [result appendString:@"OS-Level Logs Export\n"];
    [result appendString:@"─────────────────────────────────\n\n"];
    
    // Get both Ad SDK filtered and raw OS logs
    NSArray *adSdkLogs = [self fetchAdSdkLogs];
    NSArray *osRawLogs = [self fetchOSRawLogs];
    
    [result appendFormat:@"=== Ad SDK Logs (Filtered) (%lu) ===\n\n", (unsigned long)adSdkLogs.count];
    for (NSDictionary *log in adSdkLogs) {
        [result appendFormat:@"%@\n", log[@"message"]];
    }
    
    [result appendFormat:@"\n=== OS Raw Logs (Unfiltered) (%lu) ===\n\n", (unsigned long)osRawLogs.count];
    for (NSDictionary *log in osRawLogs) {
        [result appendFormat:@"%@\n", log[@"message"]];
    }
    
    if (adSdkLogs.count == 0 && osRawLogs.count == 0) {
        [result appendString:@"(No OS logs captured - requires iOS 15+)\n"];
    }
    
    return result;
}

- (NSData *)createLogsZipFile {
    NSString *logsString = [self buildFilteredLogsExportString];
    
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
    NSString *buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"?";
    NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier] ?: @"unknown";
    
    // Include filter info in device header
    NSString *sourceLabel = @"CloudX";
    if (self.selectedSource == CLXLogSourceAdSDKs) sourceLabel = @"Ad SDKs";
    else if (self.selectedSource == CLXLogSourceOSRaw) sourceLabel = @"OS Raw";
    
    NSString *deviceInfo = [NSString stringWithFormat:
        @"=====================================\n"
        @"DEVICE INFORMATION\n"
        @"=====================================\n"
        @"Device: %@\n"
        @"Model: %@\n"
        @"iOS: %@\n"
        @"App: %@\n"
        @"Version: %@\n"
        @"Build: %@\n"
        @"Timestamp: %@\n"
        @"Log Source: %@\n"
        @"=====================================\n\n",
        [[UIDevice currentDevice] name],
        [[UIDevice currentDevice] model],
        [[UIDevice currentDevice] systemVersion],
        bundleId,
        appVersion,
        buildVersion,
        [[NSISO8601DateFormatter new] stringFromDate:[NSDate date]],
        sourceLabel
    ];
    
    NSString *fullContent = [deviceInfo stringByAppendingString:logsString];
    NSData *data = [fullContent dataUsingEncoding:NSUTF8StringEncoding];
    
    if (!data) return nil;
    
    return [self compressData:data];
}

- (NSData *)compressData:(NSData *)data {
    // Create gzip compressed data
    NSMutableData *compressedData = [NSMutableData data];
    
    // Gzip header
    uint8_t header[] = {0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03};
    [compressedData appendBytes:header length:sizeof(header)];
    
    // Compress with COMPRESSION_ZLIB
    size_t pageSize = 128 * 1024;
    uint8_t *compressedBuffer = malloc(pageSize);
    
    size_t compressedSize = compression_encode_buffer(
        compressedBuffer,
        pageSize,
        data.bytes,
        data.length,
        NULL,
        COMPRESSION_ZLIB
    );
    
    if (compressedSize == 0 || compressedSize > pageSize) {
        free(compressedBuffer);
        return data; // Return uncompressed as fallback
    }
    
    [compressedData appendBytes:compressedBuffer length:compressedSize];
    free(compressedBuffer);
    
    // CRC32 and size (simplified)
    uint32_t crc = 0;
    uint32_t size = (uint32_t)data.length;
    [compressedData appendBytes:&crc length:4];
    [compressedData appendBytes:&size length:4];
    
    return compressedData;
}

- (NSString *)formattedTimestamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd-HHmmss";
    return [formatter stringFromDate:[NSDate date]];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MFMailComposeResultSent:
                [self showAlertWithTitle:@"Sent!" message:@"Debug logs have been emailed successfully."];
                break;
            case MFMailComposeResultFailed:
                [self showAlertWithTitle:@"Failed" message:error.localizedDescription ?: @"Failed to send email."];
                break;
            default:
                break;
        }
    }];
}

@end

