Objective-C Migration Style Guide
Swift → Objective-C SDK Rewrite
This guide defines the canonical rules for migrating the existing Swift SDK to Objective-C. All rewritten code must conform to these standards to ensure consistency, maintainability, and seamless integration.

1. Async/Await and Result Handling
Rule:
All async Swift functions and Result<T, Error> values must be rewritten as Objective-C methods with completion blocks.
Format:
- (void)fetchDataWithCompletion:(void (^)(Data * _Nullable data, NSError * _Nullable error))completion;

Always use a single block with (result, error) pattern.
Prefer NSError for error propagation.
Do not block or simulate async behavior synchronously.

2. Delegate Patterns
Rule:
Delegate-based APIs in Swift must be preserved exactly as Objective-C @protocol-based delegates.
Conventions:
Define @protocol interfaces in header files.
Use weak delegate properties:

@property (nonatomic, weak, nullable) id<MyClassDelegate> delegate;

Wrap delegate calls in respondsToSelector: checks for safety.

3. Structs and Enums
Rule:
Swift value types must be converted to reference-style Objective-C constructs.
Structs:
Convert to @interface classes with strong or copy properties.
Immutability can be dropped unless critical.
Enums:
Use NS_ENUM:

typedef NS_ENUM(NSUInteger, AdType) {
    AdTypeBanner,
    AdTypeInterstitial,
    AdTypeRewarded
};

For associated value enums: flatten into classes with a type field and optional data.

4. Nullability Annotations
Rule:
All Objective-C public APIs must use nullability annotations.
Conventions:
Wrap all public headers with:

NS_ASSUME_NONNULL_BEGIN
...
NS_ASSUME_NONNULL_END

Use nullable only when nil is a valid return or parameter.
Annotate all blocks and property types explicitly.

5. API Naming and Swift Compatibility
Rule:
Use idiomatic Objective-C naming conventions. Add NS_SWIFT_NAME() where Swift ergonomics matter.
Conventions:
Objective-C style: fetchAdWithContext:, trackEventWithName:parameters:
Optional Swift exposure:

- (void)loadWithParams:(NSDictionary *)params NS_SWIFT_NAME(load(params:));

6. Bridging Strategy During Rewrite
Maintain Swift and Objective-C implementations in parallel during migration.
Use a test harness to validate behavior equivalence.
Do not rely on Swift bridging headers unless explicitly required for validation.

7. General Code Style
Follow Apple's Objective-C style conventions (spacing, naming, visibility).
Use #pragma mark - to group methods in implementation files.
Do not use categories for public API surface.
Split all code into .h and .m files with matching class/interface names.

8. Cursor Prompt for File Conversion
Use this standard prompt when rewriting a file using Cursor:
"Convert this Swift file to idiomatic Objective-C. Preserve delegate patterns as protocols with weak properties and respondsToSelector: checks. Convert all async or await methods into completion blocks using (result, error). Use nullability annotations (nullable, nonnull) and wrap headers with NS_ASSUME_NONNULL_BEGIN/END. Split into .h and .m files."

9. Validation
Each file must be:
Buildable in isolation
Behaviorally equivalent (via test app or unit tests)
Included in a module that builds successfully and can be demoed
Use the test harness to verify:
Ad load results
Delegate invocation order
Error paths
Any visual rendering differences

