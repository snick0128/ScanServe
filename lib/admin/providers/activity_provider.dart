import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/activity_log_model.dart';

class ActivityProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ActivityLog> _logs = [];
  bool _isLoading = false;
  String? _tenantId;

  List<ActivityLog> get logs => _logs;
  bool get isLoading => _isLoading;

  void initialize(String tenantId) {
    if (_tenantId == tenantId) return;
    _tenantId = tenantId;
    _logs = []; // Clear old logs when switching tenants
    // Delay fetch to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchLogs();
    });
  }

  Future<void> logAction({
    required String action,
    required String description,
    required String actorId,
    required String actorName,
    required String actorRole,
    required ActivityType type,
    required String tenantId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final log = ActivityLog(
        id: '', // Will be set by Firestore
        action: action,
        description: description,
        actorId: actorId,
        actorName: actorName,
        actorRole: actorRole,
        type: type,
        timestamp: DateTime.now(),
        tenantId: tenantId,
        metadata: metadata,
      );

      // Store in tenant-specific subcollection for better indexing and isolation
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('activity_logs')
          .add(log.toMap());
      
      // If we are showing logs for this tenant, refresh
      if (_tenantId == tenantId) {
        fetchLogs();
      }
    } catch (e) {
      debugPrint('🔥 Error logging activity: $e');
    }
  }

  Future<void> fetchLogs() async {
    if (_tenantId == null) return;

    // Use addPostFrameCallback to avoid "setState() or markNeedsBuild() called during build"
    // which happens when this is called from the update method of a ProxyProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoading = true;
      notifyListeners();
    });

    try {
      // Using subcollection avoids needing composite indexes for where+orderBy
      final snapshot = await _firestore
          .collection('tenants')
          .doc(_tenantId)
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      _logs = snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('🔥 Error fetching activity logs: $e');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLoading = false;
        notifyListeners();
      });
    }
  }
}
