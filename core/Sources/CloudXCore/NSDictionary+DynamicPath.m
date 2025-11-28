/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/NSDictionary+DynamicPath.h>

@implementation NSMutableDictionary (DynamicPath)

- (void)putAtDynamicPath:(NSString *)path value:(id)value {
    if (!path || path.length == 0) {
        return;
    }
    
    NSArray<NSString *> *parts = [path componentsSeparatedByString:@"."];
    if (parts.count == 0) {
        return;
    }
    
    [self putAtDynamicPathParts:parts value:value];
}

- (void)putAtDynamicPathParts:(NSArray<NSString *> *)parts value:(id)value {
    if (parts.count == 0) {
        return;
    }
    
    NSString *first = parts.firstObject;
    NSArray<NSString *> *rest = parts.count > 1 ? [parts subarrayWithRange:NSMakeRange(1, parts.count - 1)] : @[];
    
    // Check for array notation
    BOOL isWildcard = [first hasSuffix:@"[*]"];
    BOOL isIndexed = [self isArrayIndexNotation:first];
    NSString *key = [self extractKey:first];
    NSInteger index = [self extractIndex:first];
    
    if (parts.count == 1) {
        // Final segment
        if (isWildcard) {
            NSMutableArray *array = [self mutableArrayForKey:key];
            
            if (array.count == 0) {
                [array addObject:value];
            } else {
                for (NSUInteger i = 0; i < array.count; i++) {
                    array[i] = value;
                }
            }
        } else if (isIndexed && index >= 0) {
            NSMutableArray *array = [self mutableArrayForKey:key];
            
            while (array.count <= index) {
                [array addObject:[NSMutableDictionary dictionary]];
            }
            array[index] = value;
        } else {
            self[key] = value;
        }
    } else {
        // Intermediate segment
        if (isWildcard) {
            NSMutableArray *array = [self mutableArrayForKey:key];
            
            if (array.count == 0) {
                NSMutableDictionary *dummy = [NSMutableDictionary dictionary];
                [array addObject:dummy];
            }
            
            // Need to iterate with index to potentially replace immutable dicts
            for (NSUInteger i = 0; i < array.count; i++) {
                id item = array[i];
                NSMutableDictionary *mutableItem;
                
                if ([item isKindOfClass:[NSMutableDictionary class]]) {
                    mutableItem = item;
                } else if ([item isKindOfClass:[NSDictionary class]]) {
                    mutableItem = [item mutableCopy];
                    array[i] = mutableItem;
                } else {
                    continue;
                }
                [mutableItem putAtDynamicPathParts:rest value:value];
            }
        } else if (isIndexed && index >= 0) {
            NSMutableArray *array = [self mutableArrayForKey:key];
            
            while (array.count <= index) {
                [array addObject:[NSMutableDictionary dictionary]];
            }
            
            id next = array[index];
            NSMutableDictionary *mutableNext;
            
            if ([next isKindOfClass:[NSMutableDictionary class]]) {
                mutableNext = next;
            } else if ([next isKindOfClass:[NSDictionary class]]) {
                mutableNext = [next mutableCopy];
                array[index] = mutableNext;
            } else {
                mutableNext = [NSMutableDictionary dictionary];
                array[index] = mutableNext;
            }
            [mutableNext putAtDynamicPathParts:rest value:value];
        } else {
            id existing = self[key];
            NSMutableDictionary *child;
            
            if ([existing isKindOfClass:[NSMutableDictionary class]]) {
                // Already mutable, use it directly
                child = existing;
            } else if ([existing isKindOfClass:[NSDictionary class]]) {
                // Immutable dictionary - create mutable copy to preserve existing data
                child = [existing mutableCopy];
                self[key] = child;
            } else {
                // No existing value or wrong type - create new empty dict
                child = [NSMutableDictionary dictionary];
                self[key] = child;
            }
            [child putAtDynamicPathParts:rest value:value];
        }
    }
}

- (NSMutableArray *)mutableArrayForKey:(NSString *)key {
    id existing = self[key];
    NSMutableArray *array;
    
    if ([existing isKindOfClass:[NSMutableArray class]]) {
        array = existing;
    } else if ([existing isKindOfClass:[NSArray class]]) {
        // Immutable array - create mutable copy to preserve existing data
        array = [existing mutableCopy];
        self[key] = array;
    } else {
        // No existing value or wrong type - create new empty array
        array = [NSMutableArray array];
        self[key] = array;
    }
    return array;
}

- (BOOL)isArrayIndexNotation:(NSString *)segment {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".*\\[\\d+\\]" options:0 error:nil];
    NSUInteger matches = [regex numberOfMatchesInString:segment options:0 range:NSMakeRange(0, segment.length)];
    return matches > 0;
}

- (NSString *)extractKey:(NSString *)segment {
    NSRange bracketRange = [segment rangeOfString:@"["];
    if (bracketRange.location != NSNotFound) {
        return [segment substringToIndex:bracketRange.location];
    }
    return segment;
}

- (NSInteger)extractIndex:(NSString *)segment {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".*\\[(\\d+)\\]" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:segment options:0 range:NSMakeRange(0, segment.length)];
    
    if (match && match.numberOfRanges > 1) {
        NSRange indexRange = [match rangeAtIndex:1];
        NSString *indexString = [segment substringWithRange:indexRange];
        return [indexString integerValue];
    }
    
    return -1;
}

@end

