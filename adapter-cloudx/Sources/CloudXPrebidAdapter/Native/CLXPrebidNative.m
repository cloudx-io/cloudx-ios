//
//  CLXPrebidNative.m
//  CloudXPrebidAdapter
//
//  Prebid 3.0 native ad implementation
//

#import "CLXPrebidNative.h"
#import "CLXNativeAdData.h"
#import "CLXDemoAdapterError.h"
#import <SafariServices/SafariServices.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXPrebidNative ()

@property (nonatomic, strong) CloudXNativeAdData *nativeAdData;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, assign) CLXNativeTemplate type;

@end

@implementation CLXPrebidNative

@synthesize delegate;
@synthesize timeout;

- (instancetype)initWithAdm:(NSString *)adm
                                               type:(CLXNativeTemplate)type
              viewController:(UIViewController *)viewController
                                       delegate:(id<CLXAdapterNativeDelegate>)delegate {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidNative"];
    [logger info:[NSString stringWithFormat:@"🚀 [INIT] CLXPrebidNative initialization - Markup: %lu chars, Type: %ld", (unsigned long)adm.length, (long)type]];
    
    self = [super init];
    if (self) {
        self.delegate = delegate;
        self.type = type;
        self.nativeAdData = [CloudXNativeAdData parseFromJSON:adm];
        self.viewController = viewController;
        self.timeout = NO;
        
        if (self.nativeAdData) {
            [logger info:@"✅ [INIT] Native ad data parsed successfully"];
        } else {
            [logger error:@"❌ [INIT] Failed to parse native ad data from adm"];
        }
        
        [logger info:@"✅ [INIT] CLXPrebidNative initialization completed"];
    } else {
        [logger error:@"❌ [INIT] Super init failed"];
    }
    return self;
}

#pragma mark - CLXAdapterNative

- (UIView *)nativeView {
    // Get the view from the type - this is what the Swift version does
    // In Swift: type.view as? UIView
    // In Objective-C, we need to get the view from the template type
    return [self getViewForTemplate:self.type];
}

- (NSString *)sdkVersion {
    return @"1.0.0";
}

- (void)load {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidNative"];
    [logger info:@"🚀 [LOAD] CLXPrebidNative load() method called"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!self.nativeAdData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [logger error:@"❌ [LOAD] Load failed: nativeAdData is nil"];
                if ([self.delegate respondsToSelector:@selector(failToLoadWithNative:error:)]) {
                    [self.delegate failToLoadWithNative:self error:[CLXDemoAdapterError invalidAdmError]];
                }
            });
            return;
        }
        
        // Load images on background thread
        UIImage *mainImage = nil;
        UIImage *appIcon = nil;
        
        // Load main image
        if (self.nativeAdData.mainImgURL) {
            NSURL *mainImageURL = [NSURL URLWithString:self.nativeAdData.mainImgURL];
            if (mainImageURL) {
                NSData *mainImageData = [NSData dataWithContentsOfURL:mainImageURL];
                if (mainImageData) {
                    mainImage = [UIImage imageWithData:mainImageData];
                }
            }
        }
        
        // Load app icon
        if (self.nativeAdData.appIconURL) {
            NSURL *iconURL = [NSURL URLWithString:self.nativeAdData.appIconURL];
            if (iconURL) {
                NSData *iconData = [NSData dataWithContentsOfURL:iconURL];
                if (iconData) {
                    appIcon = [UIImage imageWithData:iconData];
                }
            }
        }
        
        // Move all UI operations to main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            // Get the native view on main thread
            UIView *nativeView = [self getViewForTemplate:self.type];
            
            // Set images
            if (mainImage) {
                UIImageView *mainImageView = [nativeView viewWithTag:100];
                if (mainImageView) {
                    mainImageView.image = mainImage;
                }
            }
            
            if (appIcon) {
                UIImageView *iconImageView = [nativeView viewWithTag:101];
                if (iconImageView) {
                    iconImageView.image = appIcon;
                }
            }
            
            // Set text properties
            UILabel *titleLabel = [nativeView viewWithTag:102];
            if (titleLabel) {
                titleLabel.text = self.nativeAdData.title;
            }
            
            UILabel *descriptionLabel = [nativeView viewWithTag:103];
            if (descriptionLabel) {
                descriptionLabel.text = self.nativeAdData.descriptionText;
            }
            
            UIButton *ctaButton = [nativeView viewWithTag:104];
            if (ctaButton) {
                [ctaButton setTitle:self.nativeAdData.ctatext forState:UIControlStateNormal];
                
                // Set CTA action
                [ctaButton addTarget:self action:@selector(ctaButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            }
            
            UIButton *closeButton = [nativeView viewWithTag:105];
            if (closeButton) {
                [closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            }
            
            // Notify delegate
            if ([self.delegate respondsToSelector:@selector(didLoadWithNative:)]) {
                [logger info:@"[CLXPrebidNative] load successful, notifying delegate."];
                [self.delegate didLoadWithNative:self];
            }
            
            if ([self.delegate respondsToSelector:@selector(impressionWithNative:)]) {
                [self.delegate impressionWithNative:self];
            }
        });
    });
}

- (void)ctaButtonTapped:(UIButton *)sender {
    if (self.nativeAdData.ctaLink) {
        NSURL *url = [NSURL URLWithString:self.nativeAdData.ctaLink];
        if (url) {
            SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
            [self.viewController presentViewController:safariVC animated:YES completion:nil];
            
            if ([self.delegate respondsToSelector:@selector(clickWithNative:)]) {
                [self.delegate clickWithNative:self];
            }
        }
    }
}

- (void)closeButtonTapped:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(closeWithNative:)]) {
        [self.delegate closeWithNative:self];
    }
}

- (void)destroy {
    // No cleanup needed for native ads
}

- (void)showFromViewController:(UIViewController *)viewController {
    CLXLogger *logger = [[CLXLogger alloc] initWithCategory:@"CLXPrebidNative"];
    [logger debug:@"[CLXPrebidNative] showFromViewController called"];
    // Native ad is already shown when loaded, this method is called for consistency
    if ([self.delegate respondsToSelector:@selector(didShowWithNative:)]) {
        [self.delegate didShowWithNative:self];
    }
}

#pragma mark - Private Methods

- (UIView *)getViewForTemplate:(CLXNativeTemplate)template {
    // Create a container view for the native ad
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 250)];
    containerView.backgroundColor = [UIColor whiteColor];
    containerView.layer.cornerRadius = 8;
    containerView.layer.masksToBounds = YES;
    containerView.layer.borderWidth = 1;
    containerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    // Create main image view (tag 100)
    UIImageView *mainImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 120)];
    mainImageView.tag = 100;
    mainImageView.contentMode = UIViewContentModeScaleAspectFill;
    mainImageView.clipsToBounds = YES;
    mainImageView.backgroundColor = [UIColor lightGrayColor];
    [containerView addSubview:mainImageView];
    
    // Create app icon view (tag 101)
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 130, 40, 40)];
    iconImageView.tag = 101;
    iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    iconImageView.layer.cornerRadius = 8;
    iconImageView.clipsToBounds = YES;
    iconImageView.backgroundColor = [UIColor lightGrayColor];
    [containerView addSubview:iconImageView];
    
    // Create title label (tag 102)
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 130, 250, 20)];
    titleLabel.tag = 102;
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.text = @"Ad Title";
    [containerView addSubview:titleLabel];
    
    // Create description label (tag 103)
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 150, 250, 40)];
    descriptionLabel.tag = 103;
    descriptionLabel.font = [UIFont systemFontOfSize:14];
    descriptionLabel.textColor = [UIColor darkGrayColor];
    descriptionLabel.numberOfLines = 2;
    descriptionLabel.text = @"Ad description text";
    [containerView addSubview:descriptionLabel];
    
    // Create CTA button (tag 104)
    UIButton *ctaButton = [UIButton buttonWithType:UIButtonTypeSystem];
    ctaButton.frame = CGRectMake(10, 200, 140, 40);
    ctaButton.tag = 104;
    ctaButton.backgroundColor = [UIColor systemBlueColor];
    [ctaButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    ctaButton.layer.cornerRadius = 8;
    ctaButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [ctaButton setTitle:@"Learn More" forState:UIControlStateNormal];
    [containerView addSubview:ctaButton];
    
    // Create close button (tag 105)
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(270, 10, 40, 40);
    closeButton.tag = 105;
    closeButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.layer.cornerRadius = 20;
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeButton setTitle:@"×" forState:UIControlStateNormal];
    [containerView addSubview:closeButton];
    
    return containerView;
}

@end 