#import <CloudXCore/CLXDIContainer.h>

@interface CLXDIContainer ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *factories;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *cache;
@end

@implementation CLXDIContainer

+ (instancetype)shared {
    static CLXDIContainer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _factories = [NSMutableDictionary dictionary];
        _cache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registerType:(Class)type instance:(id)instance {
    NSString *key = NSStringFromClass(type);
    self.factories[key] = instance;
}

- (nullable id)resolveType:(ServiceType)resolveType class:(Class)type {
    NSString *serviceName = NSStringFromClass(type);
    id service = nil;
    
    switch (resolveType) {
        case ServiceTypeSingleton: {
            service = self.cache[serviceName];
            if (!service) {
                service = self.factories[serviceName];
                if (service) { self.cache[serviceName] = service; }
            }
            break;
        }
        case ServiceTypeNewSingleton: {
            service = self.factories[serviceName];
            if (service) { self.cache[serviceName] = service; }
            break;
        }
        case ServiceTypeAutomatic:
        case ServiceTypeNew:
        default:
            service = self.factories[serviceName];
            break;
    }
    
    if (!service) {
#ifdef DEBUG
        // Debug-only: expected during early init before all services registered.
        // Uses NSLog to avoid circular dependency (CLXLogger may itself be resolved from DI).
        NSLog(@"[CLXDIContainer] No service registered for: %@", serviceName);
#endif
    }
    return service;
}

- (void)reset {
    [self.factories removeAllObjects];
    [self.cache removeAllObjects];
}

@end 