import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';
import 'package:intl/intl.dart';

class AllItemsPerformanceDialog extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const AllItemsPerformanceDialog({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Items Performance',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminTheme.primaryText),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Detailed view of all item sales performance.',
                      style: TextStyle(fontSize: 14, color: AdminTheme.secondaryText),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF1F3F4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FA)),
                      columns: const [
                        DataColumn(label: Text('ITEM NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('UNITS SOLD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('REVENUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                      rows: items.map((item) => DataRow(
                        cells: [
                          DataCell(Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: item['imageUrl'] != null
                                    ? Image.network(item['imageUrl'], width: 32, height: 32, fit: BoxFit.cover)
                                    : Container(color: const Color(0xFFF1F3F4), width: 32, height: 32),
                              ),
                              const SizedBox(width: 12),
                              Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          )),
                          DataCell(Text(item['units'].toString())),
                          DataCell(Text('₹${NumberFormat('#,###').format(item['revenue'])}', style: const TextStyle(fontWeight: FontWeight.bold, color: AdminTheme.primaryColor))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (item['isBestseller'] == true ? AdminTheme.success : Colors.grey[100])?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['isBestseller'] == true ? 'BESTSELLER' : 'NORMAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item['isBestseller'] == true ? AdminTheme.success : AdminTheme.secondaryText,
                              ),
                            ),
                          )),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
