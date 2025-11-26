//
//  GPPScenarioPickerView.h
//  CloudXObjCRemotePods
//
//  Created by refactoring for SOLID principles.
//
//  PURPOSE:
//  --------
//  A self-contained, reusable component for testing GPP (Global Privacy Platform) 
//  privacy compliance scenarios. Encapsulates ALL GPP test logic, UI, and SDK 
//  integration to minimize code footprint in parent view controllers.
//
//  DESIGN PRINCIPLES:
//  ------------------
//  ✅ SOLID Principles:
//     - Single Responsibility: Only manages GPP scenario testing
//     - Open/Closed: Add scenarios by editing component, not parent VCs
//     - Liskov Substitution: Works as drop-in UIView subclass
//     - Interface Segregation: Minimal public API (one optional method)
//     - Dependency Inversion: Parent VCs depend on UIView abstraction
//
//  ✅ DRY (Don't Repeat Yourself):
//     - Scenario logic defined once, reusable across all ad type VCs
//     - No duplication of GPP test code in Banner/Interstitial/Rewarded VCs
//
//  ✅ Encapsulation:
//     - Internal state management (current scenario, UI elements)
//     - Private methods handle CloudXCore SDK privacy calls
//     - Self-contained UI creation and presentation
//
//  USAGE:
//  ------
//  Simply instantiate and add to your view hierarchy. No configuration needed!
//
//  Example:
//  ```objc
//  GPPScenarioPickerView *picker = [[GPPScenarioPickerView alloc] init];
//  [stackView addArrangedSubview:picker];
//  ```
//
//  That's it! The component handles:
//  - Creating label and button UI
//  - Presenting action sheet picker
//  - Applying privacy settings to CloudXCore SDK
//  - Logging scenario changes to console
//
//  FEATURES:
//  ---------
//  📋 9 Privacy Test Scenarios:
//     1. None - No privacy settings
//     2. GPP Absent - No GPP string
//     3. CCPA Consent (.QA) - User gave consent
//     4. CCPA Opt-Out (.YA) - User opted out
//     5. Non-US (Germany) - EU privacy (GDPR)
//     6. US Non-California (NY) - US-National GPP
//     7. ⭐️ ATT Denied - iOS tracking disabled (requires Settings config)
//
//  🎯 Privacy Compliance Testing:
//     - CCPA (California Consumer Privacy Act)
//     - GPP (Global Privacy Platform - US-CA, US-National, EU)
//     - ATT (App Tracking Transparency)
//     - Regional variations (US, EU, international)
//
//  🔍 Verification:
//     - Console logging shows selected scenario
//     - CloudXCore SDK automatically applies privacy rules
//     - Bid requests reflect privacy settings (lat/lon removal, etc.)
//
//  INTEGRATION WITH IAB STANDARD STORAGE:
//  ----------------------------------------
//  Writes directly to IAB standard UserDefaults keys (CloudX reads these internally):
//  - IABGPP_HDR_GppString - IAB GPP consent string
//  - IABGPP_GppSID - IAB GPP Section ID (7=US-National, 8=US-CA/EU)
//  
//  Also calls CloudXCore public APIs for other privacy settings:
//  - setIsUserConsent: - Sets user consent flag
//  - setIsDoNotSell: - Sets CCPA do-not-sell flag
//  
//  NOTE: GPP public methods were removed from CloudX SDK to align with Android.
//  Both platforms now read GPP from IAB standard storage. Publishers should use
//  IAB CMP SDKs; this component writes to IAB keys for demo/testing purposes only.
//
//  TESTING WORKFLOW:
//  -----------------
//  1. User taps the blue scenario button
//  2. Action sheet presents with 9 scenarios + descriptions
//  3. User selects scenario
//  4. Component applies privacy settings to SDK
//  5. Component logs selection to console
//  6. Component updates button text to show active scenario
//  7. Parent VC loads ad (SDK uses privacy settings automatically)
//
//  MAINTENANCE:
//  ------------
//  To add new scenarios:
//  1. Add enum case in GPPScenarioPickerView.m
//  2. Add action in presentScenarioPickerFromViewController:
//  3. Add case in applyScenario: switch statement
//  
//  No changes needed in parent view controllers! ✅
//
//  BENEFITS:
//  ---------
//  ✅ Minimal parent VC code (3 lines vs 150+ lines before)
//  ✅ Reusable across Banner/Interstitial/Rewarded/MREC view controllers
//  ✅ Easy to maintain (change once, affects all usages)
//  ✅ Easy to test (component is self-contained unit)
//  ✅ Easy to remove (just delete component from view hierarchy)
//
//  ARCHITECTURE:
//  -------------
//      ┌─────────────────────────────────┐
//      │   BannerViewController          │
//      │   (Minimal Code - 3 lines)      │
//      └────────────┬────────────────────┘
//                   │ contains
//                   ▼
//      ┌─────────────────────────────────┐
//      │   GPPScenarioPickerView         │
//      │   (All GPP Logic)               │
//      │   - UI (label + button)         │
//      │   - Action sheet picker         │
//      │   - Scenario application        │
//      │   - IAB UserDefaults writes     │
//      └────────────┬────────────────────┘
//                   │ writes to
//                   ▼
//      ┌─────────────────────────────────┐
//      │   IAB UserDefaults              │
//      │   - IABGPP_HDR_GppString        │
//      │   - IABGPP_GppSID               │
//      └─────────────┬───────────────────┘
//                    │ read by
//                    ▼
//      ┌─────────────────────────────────┐
//      │   CloudXCore SDK                │
//      │   - Reads GPP internally        │
//      └─────────────────────────────────┘

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @class GPPScenarioPickerView
 * @brief A self-contained component for GPP privacy compliance testing
 *
 * @discussion
 * This component encapsulates all GPP (Global Privacy Platform) test scenario
 * logic, UI, and SDK integration. It provides a reusable, drop-in solution for
 * privacy compliance testing across different ad formats (Banner, Interstitial,
 * Rewarded, MREC).
 *
 * The component automatically creates its UI (label + button), presents an
 * action sheet picker, and applies selected privacy scenarios to the CloudXCore
 * SDK without requiring any configuration or method calls from the parent.
 *
 * @note This component follows SOLID principles and DRY methodology to minimize
 *       code duplication across view controllers.
 */
@interface GPPScenarioPickerView : UIView

/**
 * @brief Presents the scenario picker and applies the selected scenario
 *
 * @discussion
 * This method is optional - the component automatically presents the picker
 * when its button is tapped. Only call this method if you need to present
 * the picker programmatically from external code.
 *
 * @param viewController The view controller to present the picker from.
 *                       Must be a valid UIViewController in the view hierarchy.
 *
 * @note The component automatically finds its parent view controller when the
 *       button is tapped, so this method is rarely needed.
 *
 * @example
 * @code
 * // Optional - only if you need programmatic presentation
 * [self.gppScenarioPicker presentScenarioPickerFromViewController:self];
 * @endcode
 */
- (void)presentScenarioPickerFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END

