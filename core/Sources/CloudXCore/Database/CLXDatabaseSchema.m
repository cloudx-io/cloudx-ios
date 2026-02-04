/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXDatabaseSchema.h"

// Database Configuration
// Version 3: Renamed placementId -> adUnitId in performance_metrics_table (2.0.0 terminology migration)
const NSInteger CLXDatabaseCurrentVersion = 3;
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
           @"adUnitId TEXT NOT NULL, "
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

        // Performance Metrics Indexes (2.0.0: renamed placementId -> adUnitId)
        @"CREATE INDEX IF NOT EXISTS idx_performance_ad_unit_id ON performance_metrics_table(adUnitId)",
        @"CREATE INDEX IF NOT EXISTS idx_performance_session_id ON performance_metrics_table(sessionId)",
        @"CREATE INDEX IF NOT EXISTS idx_performance_timestamp ON performance_metrics_table(timestamp)",

        // Composite Indexes for Common Queries
        @"CREATE INDEX IF NOT EXISTS idx_metrics_session_name ON metrics_event_table(sessionId, metricName)",
        @"CREATE INDEX IF NOT EXISTS idx_performance_ad_unit_session ON performance_metrics_table(adUnitId, sessionId)"
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
    
    // Migration v3: Add adUnitId column (2.0.0 terminology migration)
    // Strategy: Add new column, leave old placementId column unused. Simpler and safer than
    // DROP/CREATE since SQLite < 3.25 (iOS 12) doesn't support RENAME COLUMN or DROP COLUMN.
    // Old placementId column remains but is ignored - new SDK code writes to adUnitId only.
    if (fromVersion < 3 && toVersion >= 3) {
        [migrations addObjectsFromArray:@[
            @"ALTER TABLE performance_metrics_table ADD COLUMN adUnitId TEXT",
            @"CREATE INDEX IF NOT EXISTS idx_performance_ad_unit_id ON performance_metrics_table(adUnitId)",
            @"CREATE INDEX IF NOT EXISTS idx_performance_ad_unit_session ON performance_metrics_table(adUnitId, sessionId)"
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