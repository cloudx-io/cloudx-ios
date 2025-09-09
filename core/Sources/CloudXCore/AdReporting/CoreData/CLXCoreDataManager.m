#import <CloudXCore/CLXCoreDataManager.h>
#import <CloudXCore/CLXLogger.h>
#import <CloudXCore/CLXAppSessionModel.h>
#import <CloudXCore/CLXSessionMetricModel.h>
#import <CloudXCore/CLXInitMetricsModel.h>
#import <CloudXCore/CLXPerformanceMetricModel.h>
#import <CloudXCore/CLXAppSession.h>
#import <CloudXCore/CLXInitMetrics.h>
#import <CloudXCore/CLXAppSessionModel+Update.h>
#import <CloudXCore/CLXInitMetricsModel+Update.h>

@interface CLXCoreDataManager ()

@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong, readwrite) NSPersistentContainer *persistentContainer;

- (instancetype)initPrivate;

@end

@implementation CLXCoreDataManager

+ (instancetype)shared {
    static CLXCoreDataManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[CLXCoreDataManager alloc] initPrivate];
    });
    return sharedInstance;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton" reason:@"Use +[CLXCoreDataManager shared]" userInfo:nil];
    return nil;
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CoreDataManager"];
        
        // Try to find the Core Data model in the main bundle first
        NSBundle *frameworkBundle = [NSBundle bundleForClass:[CLXCoreDataManager class]];
        NSURL *modelURL = [frameworkBundle URLForResource:@"CloudXDataModel" withExtension:@"momd"];

        // If not found, try to find it in the resource bundle created by CocoaPods
        if (!modelURL) {
            NSString *bundlePath = [frameworkBundle pathForResource:@"CloudXCore" ofType:@"bundle"];
            if (bundlePath) {
                 NSBundle *resourceBundle = [NSBundle bundleWithPath:bundlePath];
                 modelURL = [resourceBundle URLForResource:@"CloudXDataModel" withExtension:@"momd"];
            }
        }
        
        // As a last resort, iterate all bundles
        if (!modelURL) {
            for (NSBundle *bundle in [NSBundle allBundles]) {
                modelURL = [bundle URLForResource:@"CloudXDataModel" withExtension:@"momd"];
                if (modelURL) {
                    [_logger debug:[NSString stringWithFormat:@"Found Core Data model in fallback bundle search: %@", bundle.bundlePath]];
                    break;
                }
            }
        }

        if (!modelURL) {
            [_logger error:@"Failed to find CloudXDataModel.momd in any bundle"];
            return nil;
        }
        
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        if (!model) {
            [_logger error:@"Failed to initialize NSManagedObjectModel"];
            return nil;
        }
        
        _persistentContainer = [NSPersistentContainer persistentContainerWithName:@"CloudXMetricsContainer" managedObjectModel:model];
        [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
            if (error) {
                [self.logger error:[NSString stringWithFormat:@"Unresolved error %@, %@", error, error.userInfo]];
            }
        }];
        
        NSURL *storeURL = self.persistentContainer.persistentStoreCoordinator.persistentStores.firstObject.URL;
        [self.logger debug:[NSString stringWithFormat:@"local database is in %@", storeURL.path]];
    }
    return self;
}

- (NSManagedObjectContext *)viewContext {
    return self.persistentContainer.viewContext;
}

- (void)saveContext {
    NSManagedObjectContext *context = self.viewContext;
    [context performBlock:^{
        if ([context hasChanges]) {
            NSError *error = nil;
            if (![context save:&error]) {
                [self.logger error:[NSString stringWithFormat:@"Unable to save context: %@", error]];
            }
        }
    }];
}

- (NSArray *)fetch:(Class)objectClass {
    __block NSArray *results = @[];
    [self.viewContext performBlockAndWait:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(objectClass)];
        NSError *error = nil;
        results = [self.viewContext executeFetchRequest:request error:&error];
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Unable to fetch entities: %@", error]];
            results = @[];
        }
    }];
    return results;
}

- (CLXAppSessionModel *)fetchAppSessionWithSessionID:(NSString *)sessionID {
    __block CLXAppSessionModel *result = nil;
    [self.viewContext performBlockAndWait:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CLXAppSessionModel"];
        request.predicate = [NSPredicate predicateWithFormat:@"id == %@", sessionID];
        NSError *error = nil;
        result = [[self.viewContext executeFetchRequest:request error:&error] firstObject];
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Unable to fetch entities: %@", error]];
        }
    }];
    return result;
}

- (CLXSessionMetricModel *)fetchSessionMetricWithTimestamp:(NSDate *)timestamp {
    __block CLXSessionMetricModel *result = nil;
    [self.viewContext performBlockAndWait:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CLXSessionMetricModel"];
        request.predicate = [NSPredicate predicateWithFormat:@"timestamp == %@", timestamp];
        NSError *error = nil;
        result = [[self.viewContext executeFetchRequest:request error:&error] firstObject];
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Unable to fetch entities: %@", error]];
        }
    }];
    return result;
}

- (void)createAppSessionWithSession:(CLXAppSession *)session {
    [self.viewContext performBlock:^{
        CLXAppSessionModel *appSession = [[CLXAppSessionModel alloc] initWithContext:self.viewContext];
        appSession.url = session.url;
        appSession.appKey = session.appKey;
        appSession.id = session.sessionID;
        [self saveContext];
    }];
}

- (void)createInitMetricsWithMetrics:(CLXInitMetrics *)metrics {
    [self.viewContext performBlock:^{
        CLXInitMetricsModel *initMetrics = [[CLXInitMetricsModel alloc] initWithContext:self.viewContext];
        [initMetrics updateWithMetrics:metrics];
        [self saveContext];
    }];
}

- (void)deleteObject:(NSManagedObject *)object {
    [self.viewContext performBlock:^{
        [self.viewContext deleteObject:object];
        [self saveContext];
    }];
}

- (void)deleteAll:(Class)objectClass {
    [self.viewContext performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(objectClass)];
        NSError *error = nil;
        NSArray *results = [self.viewContext executeFetchRequest:request error:&error];
        if (error) {
            [self.logger error:[NSString stringWithFormat:@"Unable to delete all entities: %@", error]];
            return;
        }
        for (NSManagedObject *object in results) {
            [self.viewContext deleteObject:object];
        }
        [self saveContext];
    }];
}

- (void)updateAppSessionWithSession:(CLXAppSession *)session {
    [self.viewContext performBlock:^{
        CLXAppSessionModel *sessionModel = [self fetchAppSessionWithSessionID:session.sessionID];
        if (!sessionModel) {
            return;
        }
        [sessionModel updateWithSession:session];
        [self saveContext];
    }];
}

- (void)createOrGetPerformanceMetricForPlacementID:(NSString *)placementID
                                           session:(CLXAppSession *)session
                                        completion:(void (^)(CLXPerformanceMetricModel * _Nullable))completion {
    [self.viewContext performBlock:^{
        CLXAppSessionModel *sessionModel = [self fetchAppSessionWithSessionID:session.sessionID];
        if (!sessionModel) {
            completion(nil);
            return;
        }

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"placementID == %@", placementID];
        CLXPerformanceMetricModel *existingMetric = [[sessionModel.performanceMetrics filteredSetUsingPredicate:predicate] anyObject];

        if (existingMetric) {
            completion(existingMetric);
        } else {
            CLXPerformanceMetricModel *newMetric = [[CLXPerformanceMetricModel alloc] initWithContext:self.viewContext];
            newMetric.placementID = placementID;
            
            NSMutableSet *performanceMetrics = [sessionModel.performanceMetrics mutableCopy];
            [performanceMetrics addObject:newMetric];
            sessionModel.performanceMetrics = performanceMetrics;
            
            completion(newMetric);
        }
    }];
}

@end 