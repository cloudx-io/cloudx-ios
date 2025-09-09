#!/bin/bash
# CloudX Retry Control Utility

echo "🔧 CloudX Retry Control Utility"
echo "================================"
echo "🛡️  All retries default to DISABLED for IDFA protection"
echo ""

case "$1" in
    "disable-all")
        echo "🚫 Disabling all ad retries..."
        defaults write cloudx.CloudXObjCRemotePods CLXEnableBannerRetries -bool NO
        defaults write cloudx.CloudXObjCRemotePods CLXEnableInterstitialRetries -bool NO
        defaults write cloudx.CloudXObjCRemotePods CLXEnableRewardedRetries -bool NO
        defaults write cloudx.CloudXObjCRemotePods CLXEnableNativeRetries -bool NO
        echo "✅ All retries disabled"
        ;;
    "enable-all")
        echo "✅ Enabling all ad retries..."
        defaults write cloudx.CloudXObjCRemotePods CLXEnableBannerRetries -bool YES
        defaults write cloudx.CloudXObjCRemotePods CLXEnableInterstitialRetries -bool YES
        defaults write cloudx.CloudXObjCRemotePods CLXEnableRewardedRetries -bool YES
        defaults write cloudx.CloudXObjCRemotePods CLXEnableNativeRetries -bool YES
        echo "✅ All retries enabled"
        ;;
    "disable-banner")
        echo "🚫 Disabling banner retries..."
        defaults write cloudx.CloudXObjCRemotePods CLXEnableBannerRetries -bool NO
        echo "✅ Banner retries disabled"
        ;;
    "status")
        echo "📊 Current retry settings:"
        echo "Banner: $(defaults read cloudx.CloudXObjCRemotePods CLXEnableBannerRetries 2>/dev/null || echo "NO (default - protected)")"
        echo "Interstitial: $(defaults read cloudx.CloudXObjCRemotePods CLXEnableInterstitialRetries 2>/dev/null || echo "NO (default - protected)")"
        echo "Rewarded: $(defaults read cloudx.CloudXObjCRemotePods CLXEnableRewardedRetries 2>/dev/null || echo "NO (default - protected)")"
        echo "Native: $(defaults read cloudx.CloudXObjCRemotePods CLXEnableNativeRetries 2>/dev/null || echo "NO (default - protected)")"
        ;;
    *)
        echo "Usage: $0 {disable-all|enable-all|disable-banner|status}"
        echo ""
        echo "Commands:"
        echo "  disable-all     - Disable retries for all ad types (prevents IDFA blacklisting)"
        echo "  enable-all      - Enable retries for all ad types (default behavior)"
        echo "  disable-banner  - Disable only banner retries"
        echo "  status          - Show current retry settings"
        ;;
esac
