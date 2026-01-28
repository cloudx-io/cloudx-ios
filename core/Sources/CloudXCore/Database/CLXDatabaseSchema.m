/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXDatabaseSchema.h"

// Database Configuration
const NSInteger CLXDatabaseCurrentVersion = 2;
NSString * const CLXDatabaseName = @"cloudx.db";

// Table Names (matching Android exactly)
NSString * const CLXMetricsEventTableName = @"metrics_event_table";
NSString * const CLXSessionTableName = @"session_table";
NSString * const CLXPerformanceMetricsTableName = @"performance_metrics_table";

@implementation CLXDatabaseSchema

+ (NSString *)createMetricsEventTableSQL {
    return @"CREATE TABLE IF NOT EXISTS metrics_event_table ("
           @"id TEXT PRIMARY KEY NOT NULL, "
           @"metricName TEXT NOT NULL, "
           @"counter INTEGER NOT NULL DEFAULT 0, "
           @"totalLatency INTEGER NOT NULL DEFAULT 0, "
           @"sessionId TEXT NOT NULL, "
           @"auctionId TEXT NOT NULL, "
           @"created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')), "
           @"updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))"
           @")";
}

+ (NSString *)createSessionTableSQL {
    return @"CREATE TABLE IF NOT EXISTS session_table ("
           @"id TEXT PRIMARY KEY NOT NULL, "
           @"sessionId TEXT NOT NULL UNIQUE, "
           @"appKey TEXT NOT NULL, "
           @"startTime INTEGER NOT NULL, "
           @"endTime INTEGER, "
           @"duration INTEGER, "
           @"url TEXT, "
           @"created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')), "
           @"updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))"
           @")";
}

+ (NSString *)createPerformanceMetricsTableSQL {
    return @"CREATE TABLE IF NOT EXISTS performance_metrics_table ("
           @"id TEXT PRIMARY KEY NOT NULL, "
           @"placementId TEXT NOT NULL, "
           @"sessionId TEXT NOT NULL, "
           @"clickCount INTEGER NOT NULL DEFAULT 0, "
           @"impressionCount INTEGER NOT NULL DEFAULT 0, "
           @"closeCount INTEGER NOT NULL DEFAULT 0, "
           @"loadLatency INTEGER NOT NULL DEFAULT 0, "
           @"bidResponseCount INTEGER NOT NULL DEFAULT 0, "
           @"adLoadCount INTEGER NOT NULL DEFAULT 0, "
           @"adLoadLatency REAL NOT NULL DEFAULT 0.0, "
           @"bidRequestLatency REAL NOT NULL DEFAULT 0.0, "
           @"failToLoadAdCount INTEGER NOT NULL DEFAULT 0, "
           @"closeLatency REAL NOT NULL DEFAULT 0.0, "
           @"timestamp INTEGER NOT NULL, "
           @"created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')), "
           @"updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')), "
           @"FOREIGN KEY (sessionId) REFERENCES session_table(sessionId)"
           @")";
}

+ (NSArray<NSString *> *)createIndexesSQL {
    return @[
        // Metrics Event Indexes
        @"CREATE INDEX IF NOT EXISTS idx_metrics_session_id ON metrics_event_table(sessionId)",
        @"CREATE INDEX IF NOT EXISTS idx_metrics_auction_id ON metrics_event_table(auctionId)",
        @"CREATE INDEX IF NOT EXISTS idx_metrics_name ON metrics_event_table(metricName)",
        @"CREATE INDEX IF NOT EXISTS idx_metrics_created_at ON metrics_event_table(created_at)",

        // Session Indexes
        @"CREATE INDEX IF NOT EXISTS idx_session_session_id ON session_table(sessionId)",
        @"CREATE INDEX IF NOT EXISTS idx_session_app_key ON session_table(appKey)",
        @"CREATE INDEX IF NOT EXISTS idx_session_start_time ON session_table(startTime)",

        // Performance Metrics Indexes
        @"CREATE INDEX IF NOT EXISTS idx_performance_placement_id ON performance_metrics_table(placementId)",
        @"CREATE INDEX IF NOT EXISTS idx_performance_session_id ON performance_metrics_table(sessionId)",
        @"CREATE INDEX IF NOT EXISTS idx_performance_timestamp ON performance_metrics_table(timestamp)",

        // Composite Indexes for Common Queries
        @"CREATE INDEX IF NOT EXISTS idx_metrics_session_name ON metrics_event_table(sessionId, metricName)",
        @"CREATE INDEX IF NOT EXISTS idx_performance_placement_session ON performance_metrics_table(placementId, sessionId)"
    ];
}

+ (NSArray<NSString *> *)migrationSQLFromVersion:(NSInteger)fromVersion toVersion:(NSInteger)toVersion {
    NSMutableArray<NSString *> *migrations = [NSMutableArray array];
    
    // Migration from version 1 to 2: Add new performance metrics columns
    if (fromVersion < 2 && toVersion >= 2) {
        [migrations addObjectsFromArray:@[
            @"ALTER TABLE performance_metrics_table ADD COLUMN adLoadCount INTEGER NOT NULL DEFAULT 0",
            @"ALTER TABLE performance_metrics_table ADD COLUMN adLoadLatency REAL NOT NULL DEFAULT 0.0",
            @"ALTER TABLE performance_metrics_table ADD COLUMN bidRequestLatency REAL NOT NULL DEFAULT 0.0",
            @"ALTER TABLE performance_metrics_table ADD COLUMN failToLoadAdCount INTEGER NOT NULL DEFAULT 0",
            @"ALTER TABLE performance_metrics_table ADD COLUMN closeLatency REAL NOT NULL DEFAULT 0.0"
        ]];
    }
    
    return [migrations copy];
}

+ (NSString *)vacuumSQL {
    return @"VACUUM";
}

+ (NSString *)analyzeSQL {
    return @"ANALYZE";
}

@end