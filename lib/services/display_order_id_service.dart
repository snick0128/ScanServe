import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Generates concurrency-safe human-readable order IDs.
/// Format: DDMMM-TXX-XXX  e.g.  19MAY-T12-042  or  19MAY-TA-007
class DisplayOrderIdService {
  final FirebaseFirestore _firestore;

  DisplayOrderIdService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns the business date string in DDMMM format (e.g., "19MAY").
  static String businessDate([DateTime? now]) {
    final dt = now ?? DateTime.now();
    final day = dt.day.toString().padLeft(2, '0');
    final month = DateFormat('MMM').format(dt).toUpperCase();
    return '$day$month';
  }

  /// Derives a short table code from a table name.
  /// "Table 12" → "T12", "Table 1" → "T1", parcel → "TA"
  static String tableCode({required String? tableName, required bool isParcel}) {
    if (isParcel) return 'TA';
    if (tableName == null || tableName.isEmpty) return 'T0';
    final match = RegExp(r'\d+').firstMatch(tableName);
    if (match != null) return 'T${match.group(0)}';
    final clean = tableName.trim().replaceAll(' ', '').toUpperCase();
    return 'T${clean.substring(0, clean.length.clamp(1, 3))}';
  }

  /// Atomically allocates the next daily sequence number and returns the
  /// fully-formatted display ID.
  ///
  /// Uses a Firestore transaction on
  ///   tenants/{tenantId}/orderCounters/{DDMMM}
  /// so concurrent writes never produce the same sequence.
  Future<String> generate({
    required String tenantId,
    required String? tableName,
    required bool isParcel,
    DateTime? now,
  }) async {
    final date = businessDate(now);
    final code = tableCode(tableName: tableName, isParcel: isParcel);
    final counterRef = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('orderCounters')
        .doc(date);

    int sequence = 1;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      if (snap.exists) {
        sequence = ((snap.data()?['lastSequence'] as num?)?.toInt() ?? 0) + 1;
      } else {
        sequence = 1;
      }
      tx.set(
        counterRef,
        {
          'lastSequence': sequence,
          'date': date,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    final seq = sequence.toString().padLeft(3, '0');
    return '$date-$code-$seq';
  }
}
