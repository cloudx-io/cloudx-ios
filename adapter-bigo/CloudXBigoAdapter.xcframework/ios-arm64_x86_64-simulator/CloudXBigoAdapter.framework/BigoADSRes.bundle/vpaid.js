'use strict';
var VPAIDWrapper = function(VPAIDCreative, VPAIDContainer, slot, videoSlot) {
    if (!checkVPAIDInterface(VPAIDCreative)) {
        console.log("invalid VPAIDCreative: " + VPAIDCreative);
        return
    }
    this.creative = VPAIDCreative;
    this.VPAIDContainer = VPAIDContainer;
    this.slot = slot;
    this.videoSlot = videoSlot;
    this.nativeCallQueue = [];
    this.nativeCallInFlight = false;
    this.setCallbacksForCreative();

    function isFunction(str) {
        return typeof str === 'function';
    }

    function canSubscribeToEvents(adCreative) {
        return isFunction(adCreative.subscribe) || isFunction(adCreative.addEventListener) || isFunction(adCreative.on);
    }

    function canUnsubscribeFromEvents(adCreative) {
        return isFunction(adCreative.unsubscribe) || isFunction(adCreative.removeEventListener) || isFunction(adCreative.off);
    }

    function checkVPAIDInterface(VPAIDCreative) {
        //NOTE: skipAd is not part of the method list because it only appears in VPAID 2.0 and we support VPAID 1.0
        var VPAIDInterfaceMethods = [
            'handshakeVersion', 'initAd', 'startAd', 'stopAd', 'resizeAd', 'pauseAd', 'expandAd', 'collapseAd'
        ];

        for (var i = 0, len = VPAIDInterfaceMethods.length; i < len; i++) {
            if (!VPAIDCreative || !isFunction(VPAIDCreative[VPAIDInterfaceMethods[i]])) {
                return false;
            }
        }
        return canSubscribeToEvents(VPAIDCreative) && canUnsubscribeFromEvents(VPAIDCreative);
    }
};

VPAIDWrapper.prototype.nativeCallComplete = function(command) {
    if (this.nativeCallQueue.length === 0) {
        this.nativeCallInFlight = false;
        return;
    }

    var nextCall = this.nativeCallQueue.pop();
    window.location = nextCall;
};

VPAIDWrapper.prototype.isVPAIDCreativeReady = function(args) {
    if (this.creative) {
        return true;
    }
    if (args) {
        var command = args.shift();
        var msg = 'rejecting ' + command + ' because vpaid is not ready.'
        console.log(msg);
        this.executeNativeCall(['VPAIDCreativeError',
            'command', command,
            'message', msg]);
    }
    return false;
};

VPAIDWrapper.prototype.executeNativeCall = function(args) {
    var command = args.shift();
    var call = 'vpaid://' + command;

    var key, value;
    var isFirstArgument = true;

    for (var i = 0; i < args.length; i += 2) {
        key = args[i];
        value = args[i + 1];

        if (value === null) continue;

        if (isFirstArgument) {
            call += '?';
            isFirstArgument = false;
        } else {
            call += '&';
        }

        call += encodeURIComponent(key) + '=' + encodeURIComponent(value);
    }

    if (this.nativeCallInFlight) {
        this.nativeCallQueue.push(call);
    } else {
        this.nativeCallInFlight = true;
        window.location = call;
    }
};

VPAIDWrapper.prototype.callbackVPAIDEvent = function(args) {
    if (this.isVPAIDCreativeReady(args)) {
        this.executeNativeCall(args);
    }
};

VPAIDWrapper.prototype.updateVPIADContainer = function(width, height) {
    this.VPAIDContainer.style.width = width;
    this.VPAIDContainer.style.height = height;
};

VPAIDWrapper.prototype.setCallbacksForCreative = function() {
    var callbacks = {
        AdStarted: this.onStartAd,
        AdStopped: this.onStopAd,
        AdSkipped: this.onSkipAd,
        AdLoaded: this.onAdLoaded,
        AdLinearChange: this.onAdLinearChange,
        AdSizeChange: this.onAdSizeChange,
        AdExpandedChange: this.onAdExpandedChange,
        AdSkippableStateChange: this.onAdSkippableStateChange,
        AdDurationChange: this.onAdDurationChange,
        AdRemainingTimeChange: this.onAdRemainingTimeChange,
        AdVolumeChange: this.onAdVolumeChange,
        AdImpression: this.onAdImpression,
        AdClickThru: this.onAdClickThru,
        AdInteraction: this.onAdInteraction,
        AdVideoStart: this.onAdVideoStart,
        AdVideoFirstQuartile: this.onAdVideoFirstQuartile,
        AdVideoMidpoint: this.onAdVideoMidpoint,
        AdVideoThirdQuartile: this.onAdVideoThirdQuartile,
        AdVideoComplete: this.onAdVideoComplete,
        AdUserAcceptInvitation: this.onAdUserAcceptInvitation,
        AdUserMinimize: this.onAdUserMinimize,
        AdUserClose: this.onAdUserClose,
        AdPaused: this.onAdPaused,
        AdPlaying: this.onAdPlaying,
        AdError: this.onAdError,
        AdLog: this.onAdLog
    };
    for (var eventName in callbacks) {
        this.creative.subscribe(callbacks[eventName], eventName, this);
    }
};

/////////////////////////// receive events //////////////////////////////
// Pass through for initAd - when the video player wants to call the ad
VPAIDWrapper.prototype.initAd = function(width, height, viewMode, desiredBitrate, creativeData) {
    if (this.isVPAIDCreativeReady(['initAd'])) {
        this.updateVPIADContainer(width, height);
        this.videoSlot.videoSlotCanAutoPlay = true;
        this.creative.initAd(width, height, viewMode, desiredBitrate, creativeData, {
            slot:this.slot,
            videoSlot:this.videoSlot
        });
    }
};

VPAIDWrapper.prototype.handshakeVersion = function (version) {
    if (this.isVPAIDCreativeReady(['handshakeVersion'])) {
        return this.creative.handshakeVersion(version)
    } else {
        return "";
    }
};

VPAIDWrapper.prototype.resizeAd = function(width, height, viewMode) {
    if (this.isVPAIDCreativeReady(['resizeAd'])) {
        this.updateVPIADContainer(width, height);
        this.creative.resizeAd(width, height, viewMode);
    }
};

VPAIDWrapper.prototype.startAd = function() {
    if (this.isVPAIDCreativeReady(['startAd'])) {
        this.creative.startAd();
    }
};

VPAIDWrapper.prototype.pauseAd = function() {
    if (this.isVPAIDCreativeReady(['pauseAd'])) {
        this.creative.pauseAd();
    }
};

VPAIDWrapper.prototype.resumeAd = function() {
    if (this.isVPAIDCreativeReady(['resumeAd'])) {
        this.creative.resumeAd();
    }
};

VPAIDWrapper.prototype.stopAd = function() {
    if (this.isVPAIDCreativeReady(['stopAd'])) {
        this.creative.stopAd();
    }
};

VPAIDWrapper.prototype.expandAd = function() {
    if (this.isVPAIDCreativeReady(['expandAd'])) {
        this.creative.expandAd();
    }
};

VPAIDWrapper.prototype.collapseAd = function() {
    if (this.isVPAIDCreativeReady(['collapseAd'])) {
        this.creative.collapseAd();
    }
};

VPAIDWrapper.prototype.setAdVolume = function(val) {
    if (this.isVPAIDCreativeReady(['setAdVolume'])) {
        if (val <= 0) {
            this.videoSlot.muted = true;
        } else {
            this.videoSlot.muted = false;
        }
        
        this.callbackVPAIDEvent(['onAdVolumeChange',
                                 'volume', this.videoSlot.muted ? 0 : 1
        ]);
    }
};

/////////////////////////// callbck events //////////////////////////////
VPAIDWrapper.prototype.onAdError = function(message) {
    this.callbackVPAIDEvent(['onAdError',
        'message', message
    ]);
};

VPAIDWrapper.prototype.onAdLog = function(message) {
    this.callbackVPAIDEvent(['onAdLog',
        'message', message
    ]);
};

VPAIDWrapper.prototype.onAdSizeChange = function() {
    this.callbackVPAIDEvent(['onAdSizeChange',
        'w', this.creative.getAdWidth(),
        'h', this.creative.getAdHeight()
    ]);
};

VPAIDWrapper.prototype.onAdImpression = function() {
    this.callbackVPAIDEvent(['onAdImpression']);
};

VPAIDWrapper.prototype.onAdVideoStart = function() {
    this.callbackVPAIDEvent(['onAdVideoStart']);
};

VPAIDWrapper.prototype.onAdVideoFirstQuartile = function() {
    this.callbackVPAIDEvent(['onAdVideoFirstQuartile']);
};

VPAIDWrapper.prototype.onAdVideoMidpoint = function() {
    this.callbackVPAIDEvent(['onAdVideoMidpoint']);
};

VPAIDWrapper.prototype.onAdVideoThirdQuartile = function() {
    this.callbackVPAIDEvent(['onAdVideoThirdQuartile']);
};

VPAIDWrapper.prototype.onAdVideoComplete = function() {
    this.callbackVPAIDEvent(['onAdVideoComplete']);
};

VPAIDWrapper.prototype.onAdSkippableStateChange = function() {
    this.callbackVPAIDEvent(['onAdSkippableStateChange',
        'state', this.creative.getAdSkippableState()
    ]);
};

VPAIDWrapper.prototype.onAdLoaded = function() {
    this.callbackVPAIDEvent(['onAdLoaded']);
};

VPAIDWrapper.prototype.onAdPlaying = function() {
    this.callbackVPAIDEvent(['onAdPlaying']);
};

VPAIDWrapper.prototype.onStartAd = function() {
    this.callbackVPAIDEvent(['onStartAd']);
};

VPAIDWrapper.prototype.onStopAd = function() {
    this.callbackVPAIDEvent(['onStopAd']);
};

VPAIDWrapper.prototype.onSkipAd = function() {
    this.callbackVPAIDEvent(['onSkipAd']);
};

VPAIDWrapper.prototype.onAdPaused = function() {
    this.callbackVPAIDEvent(['onAdPaused']);
};

VPAIDWrapper.prototype.onAdDurationChange = function() {
    this.callbackVPAIDEvent(['onAdDurationChange',
        'duration', this.creative.getAdDuration()
    ]);
};

VPAIDWrapper.prototype.onAdRemainingTimeChange = function() {
    this.callbackVPAIDEvent(['onAdRemainingTimeChange',
        'remaining', this.creative.getAdRemainingTime()
    ]);
}

VPAIDWrapper.prototype.onAdUserAcceptInvitation = function() {
    this.callbackVPAIDEvent(['onAdUserAcceptInvitation']);
};

VPAIDWrapper.prototype.onAdUserMinimize = function() {
    this.callbackVPAIDEvent(['onAdUserMinimize']);
};

VPAIDWrapper.prototype.onAdUserClose = function() {
    this.callbackVPAIDEvent(['onAdUserClose']);
};

VPAIDWrapper.prototype.onAdExpandedChange = function() {
    this.callbackVPAIDEvent(['onAdExpandedChange',
        'expanded', this.creative.getAdExpanded()
    ]);
};

VPAIDWrapper.prototype.onAdClickThru = function(url, id, playerHandles) {
    this.callbackVPAIDEvent(['onAdClickThru',
        'url', url,
        'id', id,
        'playerHandles', playerHandles
    ]);
};

VPAIDWrapper.prototype.onAdInteraction = function(id) {
    this.callbackVPAIDEvent(['onAdInteraction',
        'id', id
    ]);
};

VPAIDWrapper.prototype.onAdLinearChange = function() {
    this.callbackVPAIDEvent(['onAdLinearChange',
        'adLinear', this.creative.getAdLinear()
    ]);
};

VPAIDWrapper.prototype.onAdVolumeChange = function() {
    var volume = this.creative.getAdVolume();
    if (volume <= 0) {
        console.log("muted");
        this.videoSlot.muted = true;
        this.videoSlot.volume = 0;
    } else {
        console.log("unmuted");
        this.videoSlot.muted = false;
        this.videoSlot.volume = volume;
    }
    this.callbackVPAIDEvent(['onAdVolumeChange',
        'volume', volume
    ]);
};

/////////////////////////// getter events //////////////////////////////
VPAIDWrapper.prototype.getAdVolume = function() {
    var volume = this.creative.getAdVolume();
    return volume;
};

VPAIDWrapper.prototype.getAdLinear = function() {
    var adLinear = this.creative.getAdLinear();
    return adLinear;
};

VPAIDWrapper.prototype.getAdExpanded = function() {
    var expanded = this.creative.getAdExpanded();
    return expanded;
};

VPAIDWrapper.prototype.getAdSkippableState = function() {
    var state = this.creative.getAdSkippableState();
    return state;
};

VPAIDWrapper.prototype.getAdRemainingTime = function() {
    var remaining = this.creative.getAdRemainingTime();
    return remaining;
};

VPAIDWrapper.prototype.getAdWidth = function() {
    var adWidth = this.creative.getAdWidth();
    return adWidth;
};

VPAIDWrapper.prototype.getAdHeight = function() {
    var adHeight = this.creative.getAdHeight();
    return adHeight;
};

VPAIDWrapper.prototype.getAdDuration = function() {
    var duration = this.creative.getAdDuration();
    return duration;
};

VPAIDWrapper.prototype.getAdCompanions = function() {
    return this.creative.getAdCompanions();
};

VPAIDWrapper.prototype.getAdIcons = function() {
    return this.creative.getAdIcons();
};
