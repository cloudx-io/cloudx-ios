#import "InitViewController.h"
#import <CloudXCore/CloudXCore.h>


@interface InitViewController ()
@property (nonatomic, assign) BOOL isSDKInitialized;
@end

@implementation InitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"[InitViewController] viewDidLoad");
    self.title = @"ObjC Demo";
    [self setupCenteredButtonWithTitle:@"Initialize SDK" action:@selector(initializeSDK)];
    
    // Check if SDK is already initialized
    self.isSDKInitialized = [[CloudXCore shared] isInitialised];
    NSLog(@"[InitViewController] isSDKInitialized after shared: %d", self.isSDKInitialized);
    [self updateStatusUIWithState:self.isSDKInitialized ? AdStateReady : AdStateNoAd];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"[InitViewController] viewWillAppear");
    self.navigationController.navigationBarHidden = NO;
    // Update UI if SDK is already initialized
    if (self.isSDKInitialized) {
        [self updateStatusUIWithState:AdStateReady];
    }
}

- (void)initializeSDK {
    NSLog(@"[InitViewController] initializeSDK called");
    if (self.isSDKInitialized) {
        NSLog(@"[InitViewController] SDK already initialized, showing alert");
        [self showAlertWithTitle:@"SDK Already Initialized" message:@"The SDK is already initialized."];
        return;
    }
    
    // SDK automatically handles IDFA and configuration - no manual setup needed
    
    [self updateStatusUIWithState:AdStateLoading];
    NSLog(@"[InitViewController] Calling CloudXCore initSDKWithAppKey:hashedUserID:completion:");
    [[CloudXCore shared] initSDKWithAppKey:@"g0PdN9_0ilfIcuNXhBopl" 
                              hashedUserID:@"test-user-123" 
                                completion:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"[InitViewController] CloudXCore initSDKWithAppKey:hashedUserID:completion: block called, success: %d, error: %@", success, error);
        if (success) {
            // Debug: Check what placements are available
            NSLog(@"🔍 [InitViewController] DEBUG: SDK initialized successfully!");
            
            
            self.isSDKInitialized = YES;
            [self updateStatusUIWithState:AdStateReady];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"cloudXSDKInitialized" object:nil];
        } else {
            NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
            [self showAlertWithTitle:@"SDK Init Failed" message:errorMessage];
        }
    }];
}


@end