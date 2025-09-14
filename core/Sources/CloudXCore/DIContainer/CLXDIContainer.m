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
    
    switch (resolveType) {
        case ServiceTypeSingleton: {
            id service = self.cache[serviceName];
            if (service) {
                return service;
            } else {
                id service = self.factories[serviceName];
                if (service) {
                    self.cache[serviceName] = service;
                }
                return service;
            }
        }
        case ServiceTypeNewSingleton: {
            id service = self.factories[serviceName];
            if (service) {
                self.cache[serviceName] = service;
            }
            return service;
        }
        case ServiceTypeAutomatic:
        case ServiceTypeNew:
        default:
            return self.factories[serviceName];
    }
}

- (void)reset {
    [self.factories removeAllObjects];
    [self.cache removeAllObjects];
}

@end 