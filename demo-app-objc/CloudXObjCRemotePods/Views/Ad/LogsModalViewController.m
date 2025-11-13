#import "LogsModalViewController.h"
#import "DemoAppLogger.h"

@interface LogsModalViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) NSString *modalTitle;
@end

@implementation LogsModalViewController

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _modalTitle = title ?: @"Logs";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self refreshLogs];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refreshLogs];
    [self scrollToBottom];
}

- (void)setupUI {
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Container view
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor systemBackgroundColor];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:containerView];
    
    // Header view
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor systemGray6Color];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:headerView];
    
    // Title label
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = self.modalTitle;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:self.titleLabel];
    
    // Close button
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setTitle:@"Close" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.closeButton addTarget:self action:@selector(closeModal) forControlEvents:UIControlEventTouchUpInside];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:self.closeButton];
    
    // Clear button
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearButton setTitle:@"Clear" forState:UIControlStateNormal];
    self.clearButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.clearButton setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
    [self.clearButton addTarget:self action:@selector(clearLogs) forControlEvents:UIControlEventTouchUpInside];
    self.clearButton.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:self.clearButton];
    
    // Scroll view
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.backgroundColor = [UIColor systemBackgroundColor];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:self.scrollView];
    
    // Stack view for logs
    self.stackView = [[UIStackView alloc] init];
    self.stackView.axis = UILayoutConstraintAxisVertical;
    self.stackView.spacing = 2;
    self.stackView.alignment = UIStackViewAlignmentFill;
    self.stackView.distribution = UIStackViewDistributionFill;
    self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.stackView];
    
    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        // Container view - fill the safe area completely
        [containerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [containerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        
        // Header view
        [headerView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [headerView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [headerView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [headerView.heightAnchor constraintEqualToConstant:50],
        
        // Title label
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:headerView.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
        
        // Close button
        [self.closeButton.trailingAnchor constraintEqualToAnchor:headerView.trailingAnchor constant:-16],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
        
        // Clear button
        [self.clearButton.leadingAnchor constraintEqualToAnchor:headerView.leadingAnchor constant:16],
        [self.clearButton.centerYAnchor constraintEqualToAnchor:headerView.centerYAnchor],
        
        // Scroll view
        [self.scrollView.topAnchor constraintEqualToAnchor:headerView.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
        
        // Stack view
        [self.stackView.topAnchor constraintEqualToAnchor:self.scrollView.topAnchor],
        [self.stackView.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor],
        [self.stackView.trailingAnchor constraintEqualToAnchor:self.scrollView.trailingAnchor],
        [self.stackView.bottomAnchor constraintEqualToAnchor:self.scrollView.bottomAnchor],
        [self.stackView.widthAnchor constraintEqualToAnchor:self.scrollView.widthAnchor]
    ]];
}

- (void)refreshLogs {
    // Clear existing log views
    for (UIView *view in self.stackView.arrangedSubviews) {
        [self.stackView removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    
    NSArray<DemoAppLogEntry *> *logs = [[DemoAppLogger sharedInstance] getAllLogs];
    
    if (logs.count == 0) {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.text = @"No logs available";
        emptyLabel.textColor = [UIColor systemGrayColor];
        emptyLabel.font = [UIFont systemFontOfSize:14];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.stackView addArrangedSubview:emptyLabel];
        return;
    }
    
    for (DemoAppLogEntry *logEntry in logs) {
        UIView *logView = [self createLogViewForEntry:logEntry];
        [self.stackView addArrangedSubview:logView];
    }
}

- (UIView *)createLogViewForEntry:(DemoAppLogEntry *)logEntry {
    UIView *containerView = [[UIView alloc] init];
    containerView.backgroundColor = [UIColor systemGray6Color];
    containerView.layer.cornerRadius = 4;
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Add margin around the log entry
    UIView *marginView = [[UIView alloc] init];
    marginView.backgroundColor = [UIColor clearColor];
    marginView.translatesAutoresizingMaskIntoConstraints = NO;
    [marginView addSubview:containerView];
    
    // Timestamp label
    UILabel *timestampLabel = [[UILabel alloc] init];
    timestampLabel.text = logEntry.formattedTimestamp;
    timestampLabel.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightMedium];
    timestampLabel.textColor = [UIColor systemBlueColor];
    timestampLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:timestampLabel];
    
    // Message label
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.text = logEntry.message;
    messageLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];
    messageLabel.textColor = [UIColor labelColor];
    messageLabel.numberOfLines = 0;
    messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [containerView addSubview:messageLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        // Container view within margin view
        [containerView.topAnchor constraintEqualToAnchor:marginView.topAnchor constant:4],
        [containerView.leadingAnchor constraintEqualToAnchor:marginView.leadingAnchor constant:12],
        [containerView.trailingAnchor constraintEqualToAnchor:marginView.trailingAnchor constant:-12],
        [containerView.bottomAnchor constraintEqualToAnchor:marginView.bottomAnchor constant:-4],
        
        // Timestamp label
        [timestampLabel.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:4],
        [timestampLabel.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:8],
        [timestampLabel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-8],
        
        // Message label
        [messageLabel.topAnchor constraintEqualToAnchor:timestampLabel.bottomAnchor constant:2],
        [messageLabel.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:8],
        [messageLabel.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-8],
        [messageLabel.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-4]
    ]];
    
    return marginView;
}

- (void)scrollToBottom {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom);
        if (bottomOffset.y > 0) {
            [self.scrollView setContentOffset:bottomOffset animated:YES];
        }
    });
}

- (void)closeModal {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)clearLogs {
    [[DemoAppLogger sharedInstance] clearLogs];
    [self refreshLogs];
}

@end
