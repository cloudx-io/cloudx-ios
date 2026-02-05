/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import "CLXDatabaseSchema.h"

// Database Configuration
// Version 4: Removed unused performance_metrics_table
const NSInteger CLXDatabaseCurrentVersion = 4;
NSString * const CLXDatabaseName = @"cloudx.db";

// Table Names (matching Android exactly)
NSString * const CLXMetricsEventTableName = @"metrics_event_table";
NSString * const CLXSessionTableName = @"session_table";

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

        // Composite Indexes for Common Queries
        @"CREATE INDEX IF NOT EXISTS idx_metrics_session_name ON metrics_event_table(sessionId, metricName)"
    ];
}

+ (NSArray<NSString *> *)migrationSQLFromVersion:(NSInteger)fromVersion toVersion:(NSInteger)toVersion {
    NSMutableArray<NSString *> *migrations = [NSMutableArray array];

    // Migration v4: Drop unused performance_metrics_table
    // The table was never used in production code. We simply stop creating it for new installs.
    // Existing databases will retain the table but it's harmless and will be ignored.
    // No explicit DROP TABLE needed - just stop using/creating it.

    return [migrations copy];
}

+ (NSString *)vacuumSQL {
    return @"VACUUM";
}

+ (NSString *)analyzeSQL {
    return @"ANALYZE";
}

@end