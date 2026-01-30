import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/orders_provider.dart';
import '../subscription/subscription_plans_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String tenantId;

  const SettingsScreen({super.key, required this.tenantId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _taxRateController;
  late TextEditingController _avgPrepTimeController;
  bool _isVegOnly = false;
  bool _captainCanDeleteItems = true;
  bool _captainRequiresApproval = false;

  // Password Change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _taxRateController = TextEditingController();
    _avgPrepTimeController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _taxRateController.dispose();
    _avgPrepTimeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('tenants').doc(widget.tenantId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _taxRateController.text = ((data['taxRate'] ?? 0.18) * 100).toString();
          _avgPrepTimeController.text = (data['avgPrepTime'] ?? 25).toString();
          _isVegOnly = data['isVegOnly'] ?? false;
          final captainSettings = data['settings']?['captainPermissions'] ?? {};
          _captainCanDeleteItems = captainSettings['canDeleteItems'] ?? true;
          _captainRequiresApproval = captainSettings['requiresApproval'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _firestore.collection('tenants').doc(widget.tenantId).update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'taxRate': double.parse(_taxRateController.text) / 100,
        'avgPrepTime': int.parse(_avgPrepTimeController.text),
        'isVegOnly': _isVegOnly,
        'settings.captainPermissions': {
          'canDeleteItems': _captainCanDeleteItems,
          'requiresApproval': _captainRequiresApproval,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    try {
      await context.read<AdminAuthProvider>().changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing password: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restaurant Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Subscription Plan Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Current Plan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demo Plan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SubscriptionPlansScreen(tenantId: 'demo'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.upgrade, size: 18),
                        label: const Text('View Plans'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _taxRateController,
              decoration: const InputDecoration(
                labelText: 'Tax Rate (%)',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val?.isEmpty == true) return 'Required';
                final num = double.tryParse(val!);
                if (num == null || num < 0 || num > 100) {
                  return 'Enter a valid percentage (0-100)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _avgPrepTimeController,
              decoration: const InputDecoration(
                labelText: 'Average Prep Time (minutes)',
                border: OutlineInputBorder(),
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val?.isEmpty == true) return 'Required';
                final num = int.tryParse(val!);
                if (num == null || num <= 0) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Vegetarian Only Restaurant'),
              value: _isVegOnly,
              onChanged: (val) => setState(() => _isVegOnly = val),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 32),
            const Text(
              'Captain / Waiter Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Can Delete Order Items'),
              subtitle: const Text('Allow captains to remove items before kitchen acceptance'),
              value: _captainCanDeleteItems,
              onChanged: (val) => setState(() => _captainCanDeleteItems = val),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Require Supervisor Approval'),
              subtitle: const Text('Require a supervisor pin for item deletions'),
              value: _captainRequiresApproval,
              onChanged: (val) => setState(() => _captainRequiresApproval = val),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 32),
            const Text(
              'Notification Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Consumer<OrdersProvider>(
              builder: (context, ordersProvider, _) {
                return SwitchListTile(
                  title: const Text('Enable Sound Alerts'),
                  subtitle: const Text('🔊 Play a sound when new orders arrive'),
                  value: ordersProvider.isSoundEnabled,
                  onChanged: (val) => ordersProvider.toggleSound(val),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
            const Divider(height: 32),
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                   TextFormField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (val) => val?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (val) => (val?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _changePassword,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
