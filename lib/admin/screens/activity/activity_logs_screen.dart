import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/activity_provider.dart';
import '../../../models/activity_log_model.dart';

class ActivityLogsScreen extends StatelessWidget {
  final String tenantId;

  const ActivityLogsScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context) ? const BackButton(color: Colors.black) : null,
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.logs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Ionicons.list_outline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    tenantId == 'global' 
                      ? 'No master console activity recorded' 
                      : 'No activity recorded for this restaurant',
                    style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Text(
                    tenantId == 'global' ? 'Global Activity Log' : 'Restaurant Activity',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ],
            body: RefreshIndicator(
              onRefresh: () => provider.fetchLogs(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.logs.length,
                itemBuilder: (context, index) {
                  final log = provider.logs[index];
                  return _buildLogItem(context, log);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, ActivityLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getTypeColor(log.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTypeIcon(log.type),
                color: _getTypeColor(log.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.action,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a, dd MMM').format(log.timestamp),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Ionicons.person_outline, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        log.actorName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.actorRole.toUpperCase(),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.menuItemAdd:
        return Ionicons.add_circle_outline;
      case ActivityType.menuItemUpdate:
        return Ionicons.create_outline;
      case ActivityType.menuItemDelete:
        return Ionicons.trash_outline;
      case ActivityType.orderStatusUpdate:
        return Ionicons.sync_outline;
      case ActivityType.orderCancel:
        return Ionicons.close_circle_outline;
      case ActivityType.tableUpdate:
        return Ionicons.apps_outline;
      case ActivityType.payment:
        return Ionicons.cash_outline;
      default:
        return Ionicons.information_circle_outline;
    }
  }

  Color _getTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.menuItemAdd:
        return Colors.green;
      case ActivityType.menuItemUpdate:
        return Colors.blue;
      case ActivityType.menuItemDelete:
        return Colors.red;
      case ActivityType.orderStatusUpdate:
        return Colors.orange;
      case ActivityType.orderCancel:
        return Colors.red;
      case ActivityType.tableUpdate:
        return Colors.purple;
      case ActivityType.payment:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
