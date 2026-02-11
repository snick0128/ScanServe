import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/session_service.dart';

class OrderTypeSelectionModal extends StatefulWidget {
  final String tenantId;
  final String guestId;
  final Function(OrderType, String?) onOrderTypeSelected;

  const OrderTypeSelectionModal({
    Key? key,
    required this.tenantId,
    required this.guestId,
    required this.onOrderTypeSelected,
  }) : super(key: key);

  @override
  State<OrderTypeSelectionModal> createState() => _OrderTypeSelectionModalState();
}

class _OrderTypeSelectionModalState extends State<OrderTypeSelectionModal> {
  OrderType? _selectedType;
  String? _selectedTableId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'How would you like to order?',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Order Type Options
              _buildOrderTypeOption(
                context,
                type: OrderType.dineIn,
                icon: Icons.restaurant,
                title: 'Dine-in',
                subtitle: 'Enjoy your meal at our restaurant',
                color: Colors.orange,
              ),

              const SizedBox(height: 16),

              _buildOrderTypeOption(
                context,
                type: OrderType.parcel,
                icon: Icons.takeout_dining,
                title: 'Parcel',
                subtitle: 'Take away or delivery',
                color: Colors.green,
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedType != null ? () {
                        widget.onOrderTypeSelected(_selectedType!, _selectedTableId);

                        // Save preferences
                        final sessionService = SessionService();
                        sessionService.saveOrderType(_selectedType!);
                        if (_selectedTableId != null) {
                          sessionService.saveTableId(_selectedTableId!);
                        }

                        Navigator.of(context).pop();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeOption(
    BuildContext context, {
    required OrderType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withAlpha(25) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color.withAlpha(50) : color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// Extension method to show the modal
extension OrderTypeModalExtension on BuildContext {
  Future<OrderType?> showOrderTypeModal({
    required String tenantId,
    required String guestId,
    required Function(OrderType, String?) onOrderTypeSelected,
  }) {
    return showModalBottomSheet<OrderType>(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderTypeSelectionModal(
        tenantId: tenantId,
        guestId: guestId,
        onOrderTypeSelected: onOrderTypeSelected,
      ),
    );
  }
}
