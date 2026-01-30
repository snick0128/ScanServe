import 'dart:async';
import 'package:uuid/uuid.dart';

typedef VoidCallback = void Function();

/// Request Debouncer with UUID-based deduplication
/// 
/// Prevents duplicate requests from rapid taps by:
/// 1. Generating unique UUIDs for each request
/// 2. Tracking recent request UUIDs
/// 3. Rejecting duplicate UUIDs within cooldown period
/// 4. Providing debounce mechanism for UI actions
class RequestDebouncer {
  static final RequestDebouncer _instance = RequestDebouncer._internal();
  factory RequestDebouncer() => _instance;
  RequestDebouncer._internal();

  final Uuid _uuid = Uuid();
  final Map<String, DateTime> _recentRequests = {};
  final Map<String, bool> _processingRequests = {};
  
  /// Default cooldown period (60 seconds)
  static const Duration defaultCooldown = Duration(seconds: 60);

  /// Generate a unique request ID
  String generateRequestId() {
    return _uuid.v4();
  }

  /// Check if a request can be processed
  /// Returns true if request is allowed, false if duplicate/too soon
  bool canProcessRequest(String requestId, {Duration? cooldown}) {
    final now = DateTime.now();
    final cooldownPeriod = cooldown ?? defaultCooldown;

    // Check if this exact request ID was used recently
    if (_recentRequests.containsKey(requestId)) {
      final lastRequestTime = _recentRequests[requestId]!;
      final timeSinceLastRequest = now.difference(lastRequestTime);
      
      if (timeSinceLastRequest < cooldownPeriod) {
        print('⚠️ Duplicate request rejected: $requestId (${timeSinceLastRequest.inSeconds}s ago)');
        return false;
      }
    }

    // Check if request is currently being processed
    if (_processingRequests[requestId] == true) {
      print('⚠️ Request already processing: $requestId');
      return false;
    }

    return true;
  }

  /// Mark request as started
  void markRequestStarted(String requestId) {
    _processingRequests[requestId] = true;
    _recentRequests[requestId] = DateTime.now();
    print('✅ Request started: $requestId');
  }

  /// Mark request as completed
  void markRequestCompleted(String requestId) {
    _processingRequests.remove(requestId);
    print('✅ Request completed: $requestId');
  }

  /// Mark request as failed
  void markRequestFailed(String requestId) {
    _processingRequests.remove(requestId);
    // Keep in recent requests to prevent retry spam
    print('❌ Request failed: $requestId');
  }

  /// Clean up old requests (older than cooldown period)
  void cleanup({Duration? cooldown}) {
    final now = DateTime.now();
    final cooldownPeriod = cooldown ?? defaultCooldown;
    
    _recentRequests.removeWhere((key, timestamp) {
      return now.difference(timestamp) > cooldownPeriod;
    });
  }

  /// Check if any request is currently processing
  bool get hasProcessingRequests => _processingRequests.isNotEmpty;

  /// Get count of processing requests
  int get processingCount => _processingRequests.length;

  /// Clear all tracked requests (use with caution)
  void reset() {
    _recentRequests.clear();
    _processingRequests.clear();
    print('🔄 RequestDebouncer reset');
  }
}

/// Debounced Action Handler
/// 
/// Wraps an async action with debouncing and UUID tracking
class DebouncedAction<T> {
  final RequestDebouncer _debouncer = RequestDebouncer();
  final Duration cooldown;
  String? _currentRequestId;

  DebouncedAction({
    this.cooldown = RequestDebouncer.defaultCooldown,
  });

  /// Execute action with debouncing
  /// Returns null if action is debounced/rejected
  Future<T?> execute(Future<T> Function(String requestId) action) async {
    // Generate new request ID
    final requestId = _debouncer.generateRequestId();

    // Check if we can process this request
    if (!_debouncer.canProcessRequest(requestId, cooldown: cooldown)) {
      return null;
    }

    // Mark as started
    _debouncer.markRequestStarted(requestId);
    _currentRequestId = requestId;

    try {
      // Execute the action
      final result = await action(requestId);
      
      // Mark as completed
      _debouncer.markRequestCompleted(requestId);
      _currentRequestId = null;
      
      return result;
    } catch (e) {
      // Mark as failed
      _debouncer.markRequestFailed(requestId);
      _currentRequestId = null;
      
      rethrow;
    }
  }

  /// Check if action is currently processing
  bool get isProcessing => _currentRequestId != null;

  /// Get current request ID (if processing)
  String? get currentRequestId => _currentRequestId;
}

/// Simple debounce timer for UI interactions
class UIDebouncer {
  Timer? _timer;
  final Duration delay;

  UIDebouncer({this.delay = const Duration(milliseconds: 500)});

  /// Run action after delay, canceling previous pending actions
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancel pending action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose of timer
  void dispose() {
    _timer?.cancel();
  }
}

/// Cooldown tracker for specific actions (e.g., waiter call)
class ActionCooldown {
  final Map<String, DateTime> _lastActionTimes = {};

  /// Check if action is on cooldown
  bool isOnCooldown(String actionKey, Duration cooldownPeriod) {
    if (!_lastActionTimes.containsKey(actionKey)) {
      return false;
    }

    final lastActionTime = _lastActionTimes[actionKey]!;
    final timeSinceLastAction = DateTime.now().difference(lastActionTime);
    
    return timeSinceLastAction < cooldownPeriod;
  }

  /// Get remaining cooldown time
  Duration getRemainingCooldown(String actionKey, Duration cooldownPeriod) {
    if (!_lastActionTimes.containsKey(actionKey)) {
      return Duration.zero;
    }

    final lastActionTime = _lastActionTimes[actionKey]!;
    final timeSinceLastAction = DateTime.now().difference(lastActionTime);
    final remaining = cooldownPeriod - timeSinceLastAction;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Mark action as executed
  void markActionExecuted(String actionKey) {
    _lastActionTimes[actionKey] = DateTime.now();
  }

  /// Reset cooldown for specific action
  void reset(String actionKey) {
    _lastActionTimes.remove(actionKey);
  }

  /// Clear all cooldowns
  void resetAll() {
    _lastActionTimes.clear();
  }
}
