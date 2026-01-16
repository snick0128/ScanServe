import 'package:flutter/material.dart';
import '../../../seed_data.dart';

class DataSeederScreen extends StatefulWidget {
  final String tenantId;
  
  const DataSeederScreen({super.key, required this.tenantId});

  @override
  State<DataSeederScreen> createState() => _DataSeederScreenState();
}

class _DataSeederScreenState extends State<DataSeederScreen> {
  bool _isSeeding = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _seedData() async {
    setState(() {
      _isSeeding = true;
      _message = null;
    });

    try {
      final seeder = DataSeeder(widget.tenantId);
      await seeder.seedAll();
      
      setState(() {
        _isSeeding = false;
        _isSuccess = true;
        _message = '✅ Successfully seeded demo data!\n\n'
            '• 8 Tables (Indoor, Outdoor, Rooftop, VIP)\n'
            '• 8 Menu Items (Pizza, Biryani, Salad, etc.)\n'
            '• 4 Sample Orders (Pending, Preparing, Ready, Completed)';
      });
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _isSuccess = false;
        _message = '❌ Error seeding data: $e';
      });
    }
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Clear All Data?'),
        content: const Text(
          'This will delete ALL tables, menu items, and orders for this tenant. '
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSeeding = true;
      _message = null;
    });

    try {
      final seeder = DataSeeder(widget.tenantId);
      await seeder.clearAll();
      
      setState(() {
        _isSeeding = false;
        _isSuccess = true;
        _message = '✅ All data cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _isSeeding = false;
        _isSuccess = false;
        _message = '❌ Error clearing data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Seeder'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.cloud_upload,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Database Seeder',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tenant: ${widget.tenantId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSuccess ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(
                        color: _isSuccess ? Colors.green[900] : Colors.red[900],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                ElevatedButton.icon(
                  onPressed: _isSeeding ? null : _seedData,
                  icon: _isSeeding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_circle),
                  label: Text(_isSeeding ? 'Seeding...' : 'Seed Demo Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: _isSeeding ? null : _clearData,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'What will be seeded?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow('📊', '8 Tables', 'Indoor, Outdoor, Rooftop, VIP sections'),
                      _buildInfoRow('🍽️', '8 Menu Items', 'Pizza, Biryani, Salads, Desserts, Drinks'),
                      _buildInfoRow('📦', '4 Sample Orders', 'Different statuses for testing'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
