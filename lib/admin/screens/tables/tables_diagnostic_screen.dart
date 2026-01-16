import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TablesDiagnosticScreen extends StatefulWidget {
  final String tenantId;
  
  const TablesDiagnosticScreen({super.key, required this.tenantId});

  @override
  State<TablesDiagnosticScreen> createState() => _TablesDiagnosticScreenState();
}

class _TablesDiagnosticScreenState extends State<TablesDiagnosticScreen> {
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  String? _error;
  bool _orderByWorks = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Test 1: Get tables without orderBy
      print('🔍 Test 1: Fetching tables without orderBy...');
      final snapshot = await firestore
          .collection('tenants')
          .doc(widget.tenantId)
          .collection('tables')
          .get();
      
      print('✅ Found ${snapshot.docs.length} tables');
      
      _tables = snapshot.docs.map((doc) {
        final data = doc.data();
        data['_docId'] = doc.id;
        return data;
      }).toList();
      
      // Test 2: Try orderBy
      print('🔍 Test 2: Testing orderBy query...');
      try {
        final orderedSnapshot = await firestore
            .collection('tenants')
            .doc(widget.tenantId)
            .collection('tables')
            .orderBy('orderIndex')
            .get();
        
        print('✅ OrderBy works! Got ${orderedSnapshot.docs.length} tables');
        _orderByWorks = true;
      } catch (e) {
        print('❌ OrderBy failed: $e');
        _orderByWorks = false;
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Diagnostic error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables Diagnostic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Card
                      Card(
                        color: _orderByWorks ? Colors.green[50] : Colors.orange[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _orderByWorks ? Icons.check_circle : Icons.warning,
                                    color: _orderByWorks ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Diagnostic Summary',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text('Tenant ID: ${widget.tenantId}'),
                              Text('Tables Found: ${_tables.length}'),
                              Text(
                                'OrderBy Index: ${_orderByWorks ? "✅ Working" : "❌ Missing"}',
                                style: TextStyle(
                                  color: _orderByWorks ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_orderByWorks) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  '⚠️ The orderBy index is missing. Tables will still work but may not be in the correct order.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Tables List
                      Text(
                        'Tables Data:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      
                      if (_tables.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No tables found in Firestore'),
                          ),
                        )
                      else
                        ..._tables.map((table) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            title: Text(table['name'] ?? 'Unnamed Table'),
                            subtitle: Text('ID: ${table['_docId']}'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...table.entries.map((entry) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              '${entry.key}:',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(entry.value.toString()),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
    );
  }
}
