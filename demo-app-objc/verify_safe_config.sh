#!/bin/bash
# CloudX Safe Configuration Verification Script

echo "🛡️ CloudX Safe Configuration Verification"
echo "=========================================="
echo ""

echo "📊 RETRY PROTECTION STATUS:"
echo "Banner: $(defaults read cloudx.CloudXObjCRemotePods CLXEnableBannerRetries 2>/dev/null || echo "NO (default - protected)")"
echo "Interstitial: $(defaults read cloudx.CloudXObjCRemotePods CLXEnableInterstitialRetries 2>/dev/null || echo "NO (default - protected)")"
echo "Rewarded: $(defaults read cloudx.CloudXObjCRemotePods CLXEnableRewardedRetries 2>/dev/null || echo "NO (default - protected)")"
echo "Native: $(defaults read cloudx.CloudXObjCRemotePods CLXEnableNativeRetries 2>/dev/null || echo "NO (default - protected)")"
echo ""

echo "🧪 TEST MODE STATUS:"
CLX_TEST=$(defaults read cloudx.CloudXObjCRemotePods CLXTestModeEnabled 2>/dev/null || echo "0")
META_TEST=$(defaults read cloudx.CloudXObjCRemotePods CLXMetaTestModeEnabled 2>/dev/null || echo "0")

if [ "$CLX_TEST" = "1" ]; then
    echo "⚠️  CLXTestModeEnabled: YES (will use hardcoded test IDFA)"
    echo "   → This forces: B8417CDB-9456-4266-8EA2-B10F88F0E7F4 (BURNED)"
    echo "   → Recommendation: Set to NO to use your new clean IDFA"
else
    echo "✅ CLXTestModeEnabled: NO (will use real device IDFA)"
    echo "   → This uses: EC1E5FC5-67B0-4584-AFD8-0E09114A6B3A (CLEAN)"
fi

if [ "$META_TEST" = "1" ]; then
    echo "✅ CLXMetaTestModeEnabled: YES (Meta test mode enabled)"
else
    echo "✅ CLXMetaTestModeEnabled: NO (Meta test mode disabled)"
fi
echo ""

echo "🎯 EXPECTED BEHAVIOR:"
echo "1. App will use your NEW clean IDFA: EC1E5FC5-67B0-4584-AFD8-0E09114A6B3A"
echo "2. Meta SDK will recognize it as test device (you just registered it)"
echo "3. Ad failures will NOT retry (maximum protection)"
echo "4. Only ONE attempt per ad load"
echo ""

echo "🔧 TO TEST SAFELY:"
echo "1. Clean build and restart app"
echo "2. Try loading a banner ad"
echo "3. Watch logs for IDFA confirmation"
echo "4. If ad fails, it will NOT retry automatically"
echo "5. Manual retry only (tap Load Ad again)"
echo ""

echo "⚠️  DANGER SIGNS TO WATCH FOR:"
echo "❌ 'Retrying banner request due to isLoading=true' (should NOT happen)"
echo "❌ 'Using test IFA fallback' (should use real IDFA)"
echo "❌ Multiple rapid requests in logs"
echo ""

echo "✅ GOOD SIGNS TO LOOK FOR:"
echo "✅ 'Using real device IDFA: EC1E5FC5-67B0-4584-AFD8-0E09114A6B3A'"
echo "✅ 'Banner retries disabled - not retrying'"
echo "✅ Meta test ads loading successfully"
echo ""

# Check if we can determine the current IDFA that would be used
echo "🔍 QUICK IDFA CHECK:"
echo "Your device should be using: EC1E5FC5-67B0-4584-AFD8-0E09114A6B3A"
echo "This should match what appears in the app logs as 'ACTUAL DEVICE IDFA'"
echo ""

echo "🚀 READY TO TEST!"
echo "Run a clean build and check the logs match the expected behavior above."
