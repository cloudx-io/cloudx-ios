window.MRAID_ENV = {
  version: '3.0',
  sdk: 'CloudX',
  sdkVersion: '{{SDK_VERSION}}',
  appId: '',
  ifa: '',
  limitAdTracking: false,
  coppa: false
};

var mraid = (function() {
  'use strict';
  
  // ============================================
  // LOGGING (routes to native CLXLogger)
  // ============================================
  // All logging goes through native - CLXLogger handles level filtering
  function mraidLog(level, message) {
    try {
      window.webkit.messageHandlers.mraid.postMessage({
        action: 'log',
        level: level,
        message: message
      });
    } catch (e) { /* Ignore if bridge not ready */ }
  }
  
  // ============================================
  // CONSOLE.LOG INTERCEPTION
  // ============================================
  // Capture creative console.* calls and route to native CLXLogger.
  // Gated on window.__CLX_RENDERER_DEBUG__ (default false) - production
  // builds do not forward creative console output across the bridge to
  // avoid log-bandwidth amplification by hostile or noisy creatives.
  if (window.__CLX_RENDERER_DEBUG__) {
    (function() {
      var originalLog = console.log;
      var originalWarn = console.warn;
      var originalError = console.error;
      var originalInfo = console.info;
      var originalDebug = console.debug;

      function forwardToNative(level, args) {
        try {
          var message = Array.prototype.slice.call(args).map(function(arg) {
            if (typeof arg === 'object') {
              try { return JSON.stringify(arg); } catch(e) { return String(arg); }
            }
            return String(arg);
          }).join(' ');

          window.webkit.messageHandlers.mraid.postMessage({
            action: 'consoleLog',
            level: level,
            message: message
          });
        } catch (e) { /* Ignore if bridge not ready */ }
      }

      console.log = function() {
        forwardToNative('debug', arguments);
        originalLog.apply(console, arguments);
      };
      console.warn = function() {
        forwardToNative('warn', arguments);
        originalWarn.apply(console, arguments);
      };
      console.error = function() {
        forwardToNative('error', arguments);
        originalError.apply(console, arguments);
      };
      console.info = function() {
        forwardToNative('info', arguments);
        originalInfo.apply(console, arguments);
      };
      console.debug = function() {
        forwardToNative('verbose', arguments);
        originalDebug.apply(console, arguments);
      };
    })();
  }
  
  // ============================================
  // STATE VARIABLES
  // ============================================
  var state = 'loading';
  var placementType = '{{PLACEMENT_TYPE}}';
  var isViewable = false;
  var volumePercentage = null;
  var resizePropertiesInitialized = false;
  
  // Orientation properties
  var orientationProperties = {
    allowOrientationChange: true,
    forceOrientation: 'none'
  };
  
  // Expand properties
  var expandProperties = {
    width: {{EXPAND_WIDTH}},
    height: {{EXPAND_HEIGHT}},
    useCustomClose: false,
    isModal: true
  };
  
  // Resize properties
  var resizeProperties = {
    width: {{RESIZE_WIDTH}},
    height: {{RESIZE_HEIGHT}},
    customClosePosition: 'top-right',
    offsetX: 0,
    offsetY: 0,
    allowOffscreen: true
  };
  
  // Position tracking - CRITICAL: defaultPosition is separate from currentPosition
  var defaultPosition = { x: {{DEFAULT_POS_X}}, y: {{DEFAULT_POS_Y}}, width: {{DEFAULT_POS_WIDTH}}, height: {{DEFAULT_POS_HEIGHT}} };
  var currentPosition = { x: {{CURRENT_POS_X}}, y: {{CURRENT_POS_Y}}, width: {{CURRENT_POS_WIDTH}}, height: {{CURRENT_POS_HEIGHT}} };
  var maxSize = { width: {{MAX_WIDTH}}, height: {{MAX_HEIGHT}} };
  var screenSize = { width: {{SCREEN_WIDTH}}, height: {{SCREEN_HEIGHT}} };
  
  // Current app orientation (MRAID 3.0)
  var currentAppOrientation = {
    orientation: 'portrait',
    locked: false
  };
  
  // DC-13: Location state removed. Native never calls setLocation; location is
  // supplied via OpenRTB bid request, not MRAID. getLocation() returns -1 per spec.
  
  // Exposure tracking (MRAID 3.0)
  var lastExposure = {
    exposedPercentage: 0.0,
    visibleRectangle: { x: 0, y: 0, width: 0, height: 0 },
    occlusionRectangles: null
  };
  
  // NON-SUPPORT DECISION: calendar, storePicture, and location report false.
  // - calendar/storePicture: require iOS permissions the SDK must not trigger;
  //   delegated to host app which does not implement them.
  // - location: always returns -1; location is supplied via OpenRTB bid request, not MRAID.
  // Do not change these to true without a product decision and host-app integration.
  var allSupports = {
    sms: false,
    tel: false,
    calendar: false,
    storePicture: false,
    inlineVideo: {{INLINE_VIDEO}},
    location: false
  };
  
  // Event listeners
  var eventListeners = {};

  // CXD-1664: `ready` event idempotency. markReady() flips this once and
  // ignores subsequent invocations so the creative observes `ready`
  // exactly once even if native re-invokes markReady() on a navigation
  // retry or re-injection.
  var readyFired = false;
  
  // ============================================
  // TRANSITION HANDLING
  // Coalesces non-error events emitted while the runtime is mid-transition
  // (e.g. layout updates that fire as the creative is moving between
  // default/expanded/resized). Events accumulated in eventsQueue are flushed
  // once transitionLevel returns to zero, with the newest payload per event
  // type winning. Error events bypass the queue so creative-side handlers
  // see failures immediately.
  // ============================================
  var eventsQueue = [];
  var transitionLevel = 0;
  var isTransitionToExpand = false;
  
  function addEventToQueue(eventInfo) {
    // Store only newest event with args, except error events
    if (eventInfo.event !== 'error') {
      var eventIndex = eventsQueue.findIndex(function(item) {
        return item.event === eventInfo.event;
      });
      if (eventIndex !== -1) {
        eventsQueue.splice(eventIndex, 1);
      }
    }
    eventsQueue.push(eventInfo);
  }
  
  function finishTransition() {
    isTransitionToExpand = false;
    // Keep transitionLevel high while clearing queue
    while (eventsQueue.length > 0 && transitionLevel === 1) {
      var eventInfo = eventsQueue.shift();
      fireEvent(eventInfo.event, eventInfo.args);
    }
    transitionLevel--;
  }
  
  // ============================================
  // NATIVE CALL QUEUE
  // Serializes JS-to-native bridge calls so the native side processes one
  // message at a time. callNative() flips nativeCallInProcess true before
  // posting; the native handler MUST drive _internal.nativeCallComplete()
  // (on every accepted AND rejected path) to flip it back, which drains the
  // queue. Without this invariant a single rejection wedges the queue and
  // every subsequent mraid call is silently buffered forever.
  // ============================================
  var nativeCallQueue = [];
  var nativeCallInProcess = false;
  
  function callNative(action, data) {
    var message = Object.assign({ action: action }, data || {});
    if (nativeCallInProcess) {
      nativeCallQueue.push(message);
    } else {
      nativeCallInProcess = true;
      window.webkit.messageHandlers.mraid.postMessage(message);
    }
  }
  
  // ============================================
  // EVENT SYSTEM
  // ============================================
  function fireEvent(event, args) {
    var handlers = eventListeners[event];
    if (!handlers) return;
    
    for (var i = 0; i < handlers.length; i++) {
      try {
        if (event === 'ready') {
          handlers[i]();
        } else if (event === 'error') {
          // CRITICAL: Error receives TWO arguments (message, action)
          handlers[i](args[0], args[1]);
        } else if (event === 'stateChange' || event === 'viewableChange') {
          handlers[i](args);
        } else if (event === 'sizeChange') {
          handlers[i](args[0], args[1]);
        } else if (event === 'exposureChange') {
          handlers[i](lastExposure.exposedPercentage, lastExposure.visibleRectangle, lastExposure.occlusionRectangles);
        } else if (event === 'audioVolumeChange') {
          handlers[i](args);
        }
      } catch(e) {
        console.log('MRAID event handler error:', e);
      }
    }
  }

  function safeURLDescription(url) {
    try {
      var parsed = new URL(String(url), document.location.href);
      return parsed.host ? parsed.protocol + '//' + parsed.host : parsed.protocol.replace(':', '');
    } catch (e) {
      var value = String(url || '');
      var match = value.match(/^([a-zA-Z][a-zA-Z0-9+.-]*):/);
      return match ? match[1].toLowerCase() : '(no scheme)';
    }
  }
  
  // ============================================
  // INTERNAL STATE HANDLERS (called by native)
  // ============================================
  function onReady() {
    onStateChange('default');
    fireEvent('ready');
  }

  // CXD-1664: native-owned `ready` event timing. Invoked from
  // CLXCoreMRAIDManager.webViewDidFinishNavigation after the manager has
  // seeded MRAID geometry (default position, current position, screen size,
  // max size, viewability). Idempotent across repeated native invocations
  // so a re-injection from a navigation retry does not double-fire `ready`.
  function markReady() {
    if (readyFired) return;
    readyFired = true;
    onReady();
  }
  
  function onReadyExpanded() {
    onStateChange('expanded');
    fireEvent('ready');
  }
  
  function onStateChange(newState) {
    // (PR #740 review finding F1.) A legitimate same-state native callback
    // (e.g. resized → resized re-position) must still drain the transition
    // queue or transitionLevel stays pinned and subsequent native events
    // queue indefinitely. Dedupe only the creative-facing fireEvent below;
    // the finishTransition path runs whenever the native side calls back,
    // regardless of whether the state value changed.
    var stateChanged = (state !== newState);
    if (stateChanged) {
      state = newState;
    }
    if (transitionLevel > 0) {
      if (stateChanged) {
        addEventToQueue({ event: 'stateChange', args: state });
      }
      finishTransition();
    } else if (stateChanged) {
      fireEvent('stateChange', state);
    }
  }
  
  function onViewableChange(viewable) {
    isViewable = viewable;
    if (transitionLevel > 0) {
      addEventToQueue({ event: 'viewableChange', args: isViewable });
    } else {
      fireEvent('viewableChange', isViewable);
    }
  }
  
  function onSizeChange(width, height) {
    if (transitionLevel > 0) {
      addEventToQueue({ event: 'sizeChange', args: [width, height] });
    } else {
      fireEvent('sizeChange', [width, height]);
    }
  }
  
  function onExposureChange(exposureJSON) {
    var exposure = typeof exposureJSON === 'string' ? JSON.parse(exposureJSON) : exposureJSON;
    lastExposure = exposure;
    if (transitionLevel > 0) {
      addEventToQueue({ event: 'exposureChange' });
    } else {
      fireEvent('exposureChange');
    }
  }
  
  function onAudioVolumeChange(newVolumePercentage) {
    volumePercentage = newVolumePercentage;
    if (transitionLevel > 0) {
      addEventToQueue({ event: 'audioVolumeChange', args: newVolumePercentage });
    } else {
      fireEvent('audioVolumeChange', newVolumePercentage);
    }
  }
  
  function onError(message, action) {
    if (transitionLevel > 0) {
      addEventToQueue({ event: 'error', args: [message, action] });
      if (action === 'expand' || action === 'resize' || action === 'close') {
        finishTransition();
      }
    } else {
      fireEvent('error', [message, action]);
    }
  }
  
  // ============================================
  // PUBLIC MRAID API
  // ============================================
  var publicAPI = {
    // Version
    getVersion: function() { mraidLog('debug', 'getVersion: 3.0'); return '3.0'; },
    
    // State
    getState: function() { mraidLog('debug', 'getState: ' + state); return state; },
    getPlacementType: function() { mraidLog('debug', 'getPlacementType: ' + placementType); return placementType; },
    isViewable: function() { mraidLog('debug', 'isViewable: ' + isViewable); return isViewable; },
    
    // ============================================
    // EVENT LISTENERS
    // ============================================
    addEventListener: function(event, listener) {
      var handlers = eventListeners[event];
      if (!handlers) {
        handlers = eventListeners[event] = [];
      }
      // Check if listener already present
      for (var i = 0; i < handlers.length; i++) {
        if (listener === handlers[i]) return;
      }
      handlers.push(listener);
      
      // MRAID 3.0: Fire initial exposure/volume on registration
      if (event === 'exposureChange') {
        setTimeout(function() { fireEvent('exposureChange'); }, 0);
      }
      if (event === 'audioVolumeChange') {
        setTimeout(function() { fireEvent('audioVolumeChange', volumePercentage); }, 0);
      }
    },
    
    removeEventListener: function(event, listener) {
      var handlers = eventListeners[event];
      if (handlers) {
        for (var i = 0; i < handlers.length; i++) {
          if (handlers[i] === listener) {
            handlers.splice(i, 1);
            break;
          }
        }
      }
    },
    
    // ============================================
    // ACTIONS
    // ============================================
    open: function(url) {
      mraidLog('debug', 'open: ' + safeURLDescription(url));
      callNative('open', { url: url });
    },
    
    close: function() {
      mraidLog('debug', 'close');
      transitionLevel++;
      callNative('close');
    },
    
    expand: function(url) {
      mraidLog('debug', 'expand: ' + (url ? safeURLDescription(url) : '(no URL)'));
      if (url) {
        transitionLevel++;
        callNative('expand', { url: url });
      } else {
        if (!isTransitionToExpand && state !== 'expanded') {
          transitionLevel++;
          isTransitionToExpand = true;
        }
        callNative('expand');
      }
    },
    
    resize: function() {
      mraidLog('debug', 'resize: ' + JSON.stringify(resizeProperties));
      if (!resizePropertiesInitialized) {
        onError('Resize properties not initialized. Call setResizeProperties first.', 'resize');
        return;
      }
      transitionLevel++;
      callNative('resize', { properties: resizeProperties });
    },
    
    playVideo: function(url) {
      mraidLog('debug', 'playVideo: ' + safeURLDescription(url));
      callNative('playVideo', { url: url });
    },
    
    storePicture: function(url) {
      mraidLog('debug', 'storePicture: ' + safeURLDescription(url));
      callNative('storePicture', { url: url });
    },
    
    createCalendarEvent: function(parameters) {
      mraidLog('debug', 'createCalendarEvent: ' + JSON.stringify(parameters));
      callNative('createCalendarEvent', { parameters: JSON.stringify(parameters) });
    },
    
    unload: function() {
      mraidLog('debug', 'unload');
      callNative('unload');
    },
    
    // ============================================
    // POSITION & SIZE
    // ============================================
    getCurrentPosition: function() { mraidLog('debug', 'getCurrentPosition: ' + JSON.stringify(currentPosition)); return currentPosition; },
    getDefaultPosition: function() { mraidLog('debug', 'getDefaultPosition: ' + JSON.stringify(defaultPosition)); return defaultPosition; },
    getMaxSize: function() { mraidLog('debug', 'getMaxSize: ' + JSON.stringify(maxSize)); return maxSize; },
    getScreenSize: function() { mraidLog('debug', 'getScreenSize: ' + JSON.stringify(screenSize)); return screenSize; },
    
    // ============================================
    // EXPAND PROPERTIES
    // ============================================
    getExpandProperties: function() {
      expandProperties.isModal = true;
      mraidLog('debug', 'getExpandProperties: ' + JSON.stringify(expandProperties));
      return expandProperties;
    },
    
    setExpandProperties: function(properties) {
      mraidLog('debug', 'setExpandProperties: ' + JSON.stringify(properties));
      if (!properties) return;
      if (properties.width != null && !isNaN(properties.width)) {
        expandProperties.width = properties.width;
      }
      if (properties.height != null && !isNaN(properties.height)) {
        expandProperties.height = properties.height;
      }
    },
    
    // ============================================
    // RESIZE PROPERTIES
    // setResizeProperties enforces the MRAID 3.0 resize envelope: width and
    // height must be positive numbers, customClosePosition must be one of
    // the recognized anchor strings, and offsets must be numeric. Invalid
    // input flips resizePropertiesInitialized back to false so a subsequent
    // mraid.resize() call surfaces a deterministic error instead of acting
    // on a half-validated dictionary.
    // ============================================
    getResizeProperties: function() { mraidLog('debug', 'getResizeProperties: ' + JSON.stringify(resizeProperties)); return resizeProperties; },
    
    setResizeProperties: function(properties) {
      mraidLog('debug', 'setResizeProperties: ' + JSON.stringify(properties));
      resizePropertiesInitialized = false;
      
      if (!properties) {
        onError('properties is null', 'setResizeProperties');
        return;
      }
      
      // Validate maxSize available
      if (!maxSize || !maxSize.width || !maxSize.height) {
        onError('Unable to use maxSize of [' + JSON.stringify(maxSize) + ']', 'setResizeProperties');
        return;
      }
      
      // Width validation
      if (properties.width == null || typeof properties.width === 'undefined' || isNaN(properties.width)) {
        onError('width param of [' + properties.width + '] is unusable.', 'setResizeProperties');
        return;
      }
      if (properties.width < 50 || properties.width > maxSize.width) {
        onError('width param of [' + properties.width + '] outside acceptable range of 50 to ' + maxSize.width, 'setResizeProperties');
        return;
      }
      
      // Height validation
      if (properties.height == null || typeof properties.height === 'undefined' || isNaN(properties.height)) {
        onError('height param of [' + properties.height + '] is unusable.', 'setResizeProperties');
        return;
      }
      if (properties.height < 50 || properties.height > maxSize.height) {
        onError('height param of [' + properties.height + '] outside acceptable range of 50 to ' + maxSize.height, 'setResizeProperties');
        return;
      }
      
      // Offset validation
      if (properties.offsetX == null || typeof properties.offsetX === 'undefined' || isNaN(properties.offsetX)) {
        onError('offsetX param of [' + properties.offsetX + '] is unusable.', 'setResizeProperties');
        return;
      }
      if (properties.offsetY == null || typeof properties.offsetY === 'undefined' || isNaN(properties.offsetY)) {
        onError('offsetY param of [' + properties.offsetY + '] is unusable.', 'setResizeProperties');
        return;
      }
      
      // allowOffscreen validation
      if (typeof properties.allowOffscreen !== 'boolean') {
        onError('allowOffscreen param of [' + properties.allowOffscreen + '] is unusable.', 'setResizeProperties');
        return;
      }
      
      // All validations passed - set properties
      resizeProperties.width = properties.width;
      resizeProperties.height = properties.height;
      resizeProperties.customClosePosition = properties.customClosePosition || 'top-right';
      resizeProperties.offsetX = properties.offsetX;
      resizeProperties.offsetY = properties.offsetY;
      resizeProperties.allowOffscreen = properties.allowOffscreen;
      
      resizePropertiesInitialized = true;
    },
    
    // ============================================
    // ORIENTATION PROPERTIES
    // ============================================
    getOrientationProperties: function() { mraidLog('debug', 'getOrientationProperties: ' + JSON.stringify(orientationProperties)); return orientationProperties; },
    
    setOrientationProperties: function(properties) {
      mraidLog('debug', 'setOrientationProperties: ' + JSON.stringify(properties));
      if (!properties) return;
      var aoc = properties.allowOrientationChange;
      if (aoc === true || aoc === false) {
        orientationProperties.allowOrientationChange = aoc;
      }
      var fo = properties.forceOrientation;
      if (fo === 'landscape' || fo === 'portrait' || fo === 'none') {
        orientationProperties.forceOrientation = fo;
      }
      callNative('onOrientationPropertiesChanged', { properties: JSON.stringify(orientationProperties) });
    },
    
    // ============================================
    // MRAID 3.0: APP ORIENTATION
    // ============================================
    getCurrentAppOrientation: function() {
      var result = { orientation: currentAppOrientation.orientation, locked: currentAppOrientation.locked };
      mraidLog('debug', 'getCurrentAppOrientation: ' + JSON.stringify(result));
      return result;
    },
    
    // ============================================
    // FEATURE SUPPORT
    // ============================================
    supports: function(feature) {
      var result = allSupports[feature] || false;
      mraidLog('debug', 'supports(' + feature + '): ' + result);
      return result;
    },
    
    // ============================================
    // LOCATION (MRAID 3.0)
    // ============================================
    getLocation: function() {
      mraidLog('debug', 'getLocation: unavailable (location via OpenRTB, not MRAID)');
      onError('-1', 'getLocation');
      return '-1';
    },
    
    // ============================================
    // MRAID 3.0: AUDIO VOLUME
    // ============================================
    getAudioVolumePercentage: function() {
      mraidLog('debug', 'getAudioVolumePercentage: ' + volumePercentage);
      return volumePercentage;
    },
    
    // ============================================
    // MRAID 3.0: EXPOSURE PROPERTIES
    // ============================================
    getExposureProperties: function() {
      mraidLog('debug', 'getExposureProperties: ' + JSON.stringify(lastExposure));
      return lastExposure;
    },
    
    // ============================================
    // NON-SUPPORT DECISION: useCustomClose is deprecated in MRAID 3.0.
    // The SDK close button must always remain visible for App Store compliance
    // and MRC ad measurement guidelines. Do not re-implement.
    // ============================================
    useCustomClose: function(useCustomClose) {
      mraidLog('warn', 'useCustomClose() is deprecated in MRAID 3.0 and ignored by this SDK');
      onError('useCustomClose is not supported.', 'useCustomClose');
    },
    
    // useCustomClose is the last public method — internal functions live on _internal below
  };
  
  // P2-20: Internal SDK functions are not part of the public MRAID API.
  // Creatives must not call these — they are for native-to-JS communication only.
  publicAPI._internal = {
    disposables: [],
    dispose: function() {
      var queue = this.disposables;
      this.disposables = [];
      for (var i = 0; i < queue.length; i++) {
        try { queue[i](); } catch (e) {}
      }
    },

    nativeCallComplete: function() {
      if (nativeCallQueue.length === 0) {
        nativeCallInProcess = false;
      } else {
        var message = nativeCallQueue.shift();
        window.webkit.messageHandlers.mraid.postMessage(message);
      }
    },
    
    onReady: onReady,
    onReadyExpanded: onReadyExpanded,
    // CXD-1664: native-owned entry point for the `ready` event. Native
    // calls this from webViewDidFinishNavigation after geometry seeding,
    // replacing the JS-side DOMContentLoaded setTimeout that used to
    // race the native init.
    markReady: markReady,
    onStateChange: onStateChange,
    onViewableChange: onViewableChange,
    onSizeChange: onSizeChange,
    onExposureChange: onExposureChange,
    onAudioVolumeChange: onAudioVolumeChange,
    onError: onError,
    
    setMaxSize: function(w, h) {
      maxSize.width = w;
      maxSize.height = h;
    },
    setCurrentAppOrientation: function(orientation, locked) {
      currentAppOrientation.orientation = orientation;
      currentAppOrientation.locked = locked;
    },
    setDefaultPosition: function(x, y, width, height) {
      defaultPosition = { x: x, y: y, width: width, height: height };
    },
    setCurrentPosition: function(x, y, width, height) {
      currentPosition = { x: x, y: y, width: width, height: height };
    },
    setScreenSize: function(width, height) {
      screenSize = { width: width, height: height };
    },
    updateSupports: function(features) {
      if (typeof features === 'string') features = JSON.parse(features);
      Object.assign(allSupports, features);
    }
  };
  
  return publicAPI;
})();

// Make mraid globally available
window.mraid = mraid;

// CXD-1664: native owns `ready` event timing. The bundled runtime no
// longer auto-fires `ready` from DOMContentLoaded via setTimeout; native
// invokes mraid._internal.markReady() from CLXCoreMRAIDManager after
// geometry seeding completes. This eliminates the race where JS could
// fire `ready` before native finished initializing currentPosition /
// defaultPosition / screenSize / maxSize / viewability.

// ============================================================
// Content Error Monitoring (video-only)
//
// Why video-only: <img> error events are not a reliable signal of a blank
// creative. Every modern DSP creative ships 5-15+ ancillary measurement /
// sync / tracker pixels that routinely 404 in the wild (geo blocks, ad
// blockers, vendor outages, expired sync tokens). Heuristics to tell
// "the visible creative image" apart from "an ancillary tracker pixel"
// were tried (declared dimensions, bounding-rect size, computed
// display/visibility/opacity) and proved unreliable — a production DSP
// banner shipped a tracker pixel that survived every check and
// tripped the load gate against a creative that rendered correctly. The
// classifier could be tightened indefinitely; that is a maintenance hole,
// not a heuristic.
//
// <video> is structurally different: DSPs do not ship tracker-pixel
// videos. A <video> or <source> firing its error event genuinely means
// the user sees a stalled / blank creative. That signal is preserved.
//
// The blank-slot-billing case the original (image-inclusive) gate
// targeted needs a different signal anyway — paint detection or
// viewability-after-N-seconds without didImpression — not an image-error
// counter on the JS bridge.
// ============================================================
(function() {
  var reportedErrors = {}; // Prevent duplicate reports

  function safeContentErrorURLDescription(url) {
    try {
      var parsed = new URL(String(url), document.location.href);
      return parsed.host ? parsed.protocol + '//' + parsed.host : parsed.protocol.replace(':', '');
    } catch (e) {
      var value = String(url || '');
      var match = value.match(/^([a-zA-Z][a-zA-Z0-9+.-]*):/);
      return match ? match[1].toLowerCase() : '(no scheme)';
    }
  }

  // Cross-layer contract: the native gate
  // (CLXCoreMRAIDManager.handleContentError:) latches on the "video"
  // prefix of `mediaType`. Keep both in lockstep — drift silently stops
  // the gate from rejecting blank video slots.
  function reportContentError(mediaType, src, error) {
    var key = mediaType + ':' + src;
    if (reportedErrors[key]) return; // Already reported
    reportedErrors[key] = true;

    console.error('[CloudX] Content error: ' +
                  mediaType + ' failed to load: ' + safeContentErrorURLDescription(src));
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.mraid) {
      window.webkit.messageHandlers.mraid.postMessage({
        action: 'contentError',
        mediaType: mediaType,
        src: src || '(unknown)',
        error: error || 'Failed to load'
      });
    }
  }

  function setupVideoMonitoring() {
    var videos = document.querySelectorAll('video');
    videos.forEach(function(video) {
      if (video._clxErrorMonitored) return;
      video._clxErrorMonitored = true;

      video.addEventListener('error', function(e) {
        var errorMsg = 'Unknown error';
        if (video.error) {
          switch (video.error.code) {
            case 1: errorMsg = 'MEDIA_ERR_ABORTED'; break;
            case 2: errorMsg = 'MEDIA_ERR_NETWORK'; break;
            case 3: errorMsg = 'MEDIA_ERR_DECODE'; break;
            case 4: errorMsg = 'MEDIA_ERR_SRC_NOT_SUPPORTED'; break;
          }
        }
        reportContentError('video', video.src || video.currentSrc, errorMsg);
      });

      var sources = video.querySelectorAll('source');
      sources.forEach(function(source) {
        source.addEventListener('error', function(e) {
          reportContentError('video-source', source.src, 'Source failed to load');
        });
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupVideoMonitoring);
  } else {
    setupVideoMonitoring();
  }

  // Watch for dynamically added <video> elements (VAST creatives commonly
  // insert the player after the main document parses).
  var observer = new MutationObserver(function(mutations) {
    var shouldCheck = mutations.some(function(m) {
      return m.addedNodes.length > 0;
    });
    if (shouldCheck) {
      setupVideoMonitoring();
    }
  });
  observer.observe(document.body || document.documentElement, {
    childList: true,
    subtree: true
  });
  if (window.mraid && window.mraid._internal && window.mraid._internal.disposables) {
    window.mraid._internal.disposables.push(function() {
      observer.disconnect();
    });
  }
})();
