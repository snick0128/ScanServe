import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/super_admin_service.dart';
import '../../providers/admin_auth_provider.dart';

class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({super.key});

  @override
  State<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  final SuperAdminService _service = SuperAdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTenantDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Restaurant'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getTenants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tenants = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tenant = tenants[index];
                      return _buildTenantCard(tenant);
                    },
                    childCount: tenants.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final expiry = (tenant['subscriptionExpiry'] as Timestamp?)?.toDate();
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());
    final plan = tenant['plan'] ?? 'Basic';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '@${tenant['slug']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPlanColor(plan).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    plan.toUpperCase(),
                    style: TextStyle(
                      color: _getPlanColor(plan),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Ionicons.calendar_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  expiry != null ? 'Expires: ${DateFormat('dd MMM yyyy').format(expiry)}' : 'No Expiry',
                  style: TextStyle(
                    color: isExpired ? Colors.red : Colors.grey[700],
                    fontSize: 13,
                    fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.read<AdminAuthProvider>().switchTenant(
                      tenant['id'], 
                      tenant['name'] ?? 'Unknown'
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Manage'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showEditSubscriptionDialog(tenant),
                    child: const Text('Subscription'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _confirmDelete(tenant),
                  icon: const Icon(Ionicons.trash_outline, color: Colors.red, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'premium': return Colors.purple;
      case 'gold': return Colors.orange;
      default: return Colors.blue;
    }
  }

  void _showAddTenantDialog() {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedPlan = 'Basic';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Restaurant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Restaurant Name'),
            ),
            TextField(
              controller: slugController,
              decoration: const InputDecoration(labelText: 'Slug (unique-id)'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Admin Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Default Password'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPlan,
              items: ['Basic', 'Premium', 'Gold'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) => selectedPlan = v!,
              decoration: const InputDecoration(labelText: 'Subscription Plan'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _service.createTenant(
                name: nameController.text,
                slug: slugController.text,
                adminEmail: emailController.text,
                tempPassword: passwordController.text,
                plan: selectedPlan,
                expiryDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tenant created! Note: User auth must be created manually in Firebase Console.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditSubscriptionDialog(Map<String, dynamic> tenant) {
    String selectedPlan = tenant['plan'] ?? 'Basic';
    DateTime selectedDate = (tenant['subscriptionExpiry'] as Timestamp?)?.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Manage Subscription - ${tenant['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPlan,
                items: ['Basic', 'Premium', 'Gold'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) => selectedPlan = v!,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _service.updateSubscription(tenant['id'], selectedPlan, selectedDate);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> tenant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Restaurant?'),
        content: Text('This will permanently delete ${tenant['name']} and all its data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _service.deleteTenant(tenant['id']);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
