#import <CloudXCore/CLXAdapterFactoryResolver.h>
#import <CloudXCore/CLXLogger.h>

@interface CLXAdapterFactoryResolver ()
@property (nonatomic, strong) CLXLogger *logger;
@end

@implementation CLXAdapterFactoryResolver

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"AdapterFactoryResolver"];
    }
    return self;
}

- (NSDictionary *)resolveAdNetworkFactories {
    NSMutableDictionary *initializers = [NSMutableDictionary dictionary];
    NSMutableDictionary *interstitials = [NSMutableDictionary dictionary];
    NSMutableDictionary *rewardedInterstitials = [NSMutableDictionary dictionary];
    NSMutableDictionary *banners = [NSMutableDictionary dictionary];
    NSMutableDictionary *natives = [NSMutableDictionary dictionary];
    NSMutableDictionary *tokenSources = [NSMutableDictionary dictionary];
    
    [self.logger info:@"Starting factory resolution for adapters"];
    
    // Get all known adapter names (this would be equivalent to SDKConfig.KnownAdapterName.allCases in Swift)
    NSArray *knownAdapterNames = @[@"testbidder", @"googleAdManager", @"meta", @"mintegral", @"cloudx", @"prebidAdapter", @"prebidMobile"];
    
    for (NSString *adapterName in knownAdapterNames) {
        NSString *className = [self classNameForAdapterName:adapterName];
        NSString *namespace = [NSString stringWithFormat:@"CLX%@Adapter", className];
        
        [self.logger debug:[NSString stringWithFormat:@"Looking for adapter: %@, className: %@, namespace: %@", adapterName, className, namespace]];
        
        // Try to load initializer class
        Class initializerClass = [self loadClassInstanceWithNamespace:namespace className:[NSString stringWithFormat:@"CLX%@Initializer", className]];
        if (initializerClass) {
            [self.logger info:[NSString stringWithFormat:@"Initializer found for adapter: %@", adapterName]];
            // Create an instance of the initializer
            id<CLXAdNetworkInitializer> initializer = [initializerClass createInstance];
            initializers[adapterName] = initializer;
        } else {
            [self.logger info:[NSString stringWithFormat:@"Initializer NOT found for adapter: %@", adapterName]];
        }
        
        // Try to load interstitial factory class
        Class interstitialClass = [self loadClassInstanceWithNamespace:namespace className:[NSString stringWithFormat:@"CLX%@InterstitialFactory", className]];
        if (interstitialClass) {
            [self.logger info:[NSString stringWithFormat:@"InterstitialFactory found for adapter: %@ (%@)", adapterName, NSStringFromClass(interstitialClass)]];
            // Create an instance of the interstitial factory
            id<CLXAdapterInterstitialFactory> interstitialInstance = [interstitialClass createInstance];
            if (interstitialInstance) {
                [self.logger info:[NSString stringWithFormat:@"InterstitialFactory instance created successfully for adapter: %@", adapterName]];
                interstitials[adapterName] = interstitialInstance;
            } else {
                [self.logger error:[NSString stringWithFormat:@"Failed to create InterstitialFactory instance for adapter: %@", adapterName]];
            }
        } else {
            [self.logger info:[NSString stringWithFormat:@"InterstitialFactory NOT found for adapter: %@ (Looking for: CLX%@InterstitialFactory in %@)", adapterName, className, namespace]];
        }
        
        // Try to load rewarded factory class
        Class rewardedClass = [self loadClassInstanceWithNamespace:namespace className:[NSString stringWithFormat:@"CLX%@RewardedFactory", className]];
        if (rewardedClass) {
            [self.logger info:[NSString stringWithFormat:@"RewardedFactory found for adapter: %@", adapterName]];
            // Create an instance of the rewarded factory
            id<CLXAdapterRewardedFactory> rewardedInstance = [rewardedClass createInstance];
            rewardedInterstitials[adapterName] = rewardedInstance;
        } else {
            [self.logger info:[NSString stringWithFormat:@"RewardedFactory NOT found for adapter: %@", adapterName]];
        }
        
        // Try to load banner factory class
        Class bannerClass = [self loadClassInstanceWithNamespace:namespace className:[NSString stringWithFormat:@"CLX%@BannerFactory", className]];
        if (bannerClass) {
            [self.logger info:[NSString stringWithFormat:@"BannerFactory found for adapter: %@", adapterName]];
            // Create an instance of the banner factory
            id<CLXAdapterBannerFactory> bannerInstance = [bannerClass createInstance];
            banners[adapterName] = bannerInstance;
        } else {
            [self.logger info:[NSString stringWithFormat:@"BannerFactory NOT found for adapter: %@", adapterName]];
        }
        
        // Try to load native factory class
        Class nativeClass = [self loadClassInstanceWithNamespace:namespace className:[NSString stringWithFormat:@"CLX%@NativeFactory", className]];
        if (nativeClass) {
            [self.logger info:[NSString stringWithFormat:@"NativeFactory found for adapter: %@", adapterName]];
            // Create an instance of the native factory
            id<CLXAdapterNativeFactory> nativeInstance = [nativeClass createInstance];
            natives[adapterName] = nativeInstance;
        } else {
            [self.logger info:[NSString stringWithFormat:@"NativeFactory NOT found for adapter: %@", adapterName]];
        }
        
        // Try to load token source class
        Class tokenSourceClass = [self loadClassInstanceWithNamespace:namespace className:[NSString stringWithFormat:@"CLX%@BidTokenSource", className]];
        if (tokenSourceClass) {
            [self.logger info:[NSString stringWithFormat:@"TokenSource found for adapter: %@", adapterName]];
            // Create an instance of the token source
            id<CLXBidTokenSource> tokenSourceInstance = [tokenSourceClass createInstance];
            tokenSources[adapterName] = tokenSourceInstance;
        } else {
            [self.logger info:[NSString stringWithFormat:@"TokenSource NOT found for adapter: %@", adapterName]];
        }
    }
    
    [self.logger info:[NSString stringWithFormat:@"Factory resolution complete. Banner factories: %@", banners]];
    
    return @{
        @"bidTokenSources": tokenSources,
        @"initializers": initializers,
        @"interstitials": interstitials,
        @"rewardedInterstitials": rewardedInterstitials,
        @"banners": banners,
        @"native": natives,
        @"isEmpty": @(banners.count == 0 && interstitials.count == 0 && rewardedInterstitials.count == 0 && natives.count == 0 && tokenSources.count == 0 && initializers.count == 0)
    };
}

- (nullable Class)loadClassInstanceWithNamespace:(NSString *)namespace className:(NSString *)className {
    // Try with namespace first
    NSString *fullClassName = [NSString stringWithFormat:@"%@.%@", namespace, className];
    Class classInstance = NSClassFromString(fullClassName);
    
    if (classInstance) {
        [self.logger debug:[NSString stringWithFormat:@"Found class with namespace: %@", fullClassName]];
    } else {
        // Try without namespace
        classInstance = NSClassFromString(className);
        if (classInstance) {
            [self.logger debug:[NSString stringWithFormat:@"Found class without namespace: %@", className]];
        } else {
            [self.logger debug:[NSString stringWithFormat:@"Class not found with namespace '%@' or without namespace '%@'", fullClassName, className]];
        }
    }
    
    // Check if the class conforms to Instanciable protocol (has createInstance method)
    if (classInstance && [classInstance respondsToSelector:@selector(createInstance)]) {
        [self.logger debug:[NSString stringWithFormat:@"Class %@ has createInstance method", classInstance]];
        return classInstance;
    } else if (classInstance) {
        [self.logger debug:[NSString stringWithFormat:@"Class %@ found but does not have createInstance method", classInstance]];
    }
    
    return nil;
}

- (NSString *)classNameForAdapterName:(NSString *)adapterName {
    if ([adapterName isEqualToString:@"testbidder"]) {
        return @"TestVastNetwork";
    } else if ([adapterName isEqualToString:@"googleAdManager"]) {
        return @"AdManager";
    } else if ([adapterName isEqualToString:@"meta"]) {
        return @"Meta";
    } else if ([adapterName isEqualToString:@"mintegral"]) {
        return @"Mintegral";
    } else if ([adapterName isEqualToString:@"cloudx"]) {
        return @"DSP";
    } else if ([adapterName isEqualToString:@"prebidAdapter"]) {
        return @"Prebid";
    } else if ([adapterName isEqualToString:@"prebidMobile"]) {
        return @"Prebid";
    } else {
        return @"TestVastNetwork"; // default
    }
}

@end 