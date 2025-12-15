/*
 * Copyright (c) 2024 CloudX. All rights reserved.
 */

#import <CloudXCore/NSDictionary+DynamicPath.h>

@implementation NSMutableDictionary (CLXDynamicPath)

- (void)clx_putAtDynamicPath:(NSString *)path value:(id)value {
    if (!path || path.length == 0) {
        return;
    }
    
    NSArray<NSString *> *parts = [path componentsSeparatedByString:@"."];
    if (parts.count == 0) {
        return;
    }
    
    [self clx_putAtDynamicPathParts:parts value:value];
}

- (void)clx_putAtDynamicPathParts:(NSArray<NSString *> *)parts value:(id)value {
    if (parts.count == 0) {
        return;
    }
    
    NSString *first = parts.firstObject;
    NSArray<NSString *> *rest = parts.count > 1 ? [parts subarrayWithRange:NSMakeRange(1, parts.count - 1)] : @[];
    
    // Check for array notation
    BOOL isWildcard = [first hasSuffix:@"[*]"];
    BOOL isIndexed = [self clx_isArrayIndexNotation:first];
    NSString *key = [self clx_extractKey:first];
    NSInteger index = [self clx_extractIndex:first];
    
    if (parts.count == 1) {
        // Final segment
        if (isWildcard) {
            NSMutableArray *array = [self clx_mutableArrayForKey:key];
            
            if (array.count == 0) {
                [array addObject:value];
            } else {
                for (NSUInteger i = 0; i < array.count; i++) {
                    array[i] = value;
                }
            }
        } else if (isIndexed && index >= 0) {
            NSMutableArray *array = [self clx_mutableArrayForKey:key];
            
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
            NSMutableArray *array = [self clx_mutableArrayForKey:key];
            
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
                [mutableItem clx_putAtDynamicPathParts:rest value:value];
            }
        } else if (isIndexed && index >= 0) {
            NSMutableArray *array = [self clx_mutableArrayForKey:key];
            
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
            [mutableNext clx_putAtDynamicPathParts:rest value:value];
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
            [child clx_putAtDynamicPathParts:rest value:value];
        }
    }
}

- (NSMutableArray *)clx_mutableArrayForKey:(NSString *)key {
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

- (BOOL)clx_isArrayIndexNotation:(NSString *)segment {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@".*\\[\\d+\\]" options:0 error:nil];
    NSUInteger matches = [regex numberOfMatchesInString:segment options:0 range:NSMakeRange(0, segment.length)];
    return matches > 0;
}

- (NSString *)clx_extractKey:(NSString *)segment {
    NSRange bracketRange = [segment rangeOfString:@"["];
    if (bracketRange.location != NSNotFound) {
        return [segment substringToIndex:bracketRange.location];
    }
    return segment;
}

- (NSInteger)clx_extractIndex:(NSString *)segment {
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
