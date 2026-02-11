import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderTypeDialog extends StatelessWidget {
  final OrderType? initialType;

  const OrderTypeDialog({Key? key, this.initialType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Order Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _OrderTypeButton(
                  type: OrderType.dineIn,
                  icon: Icons.restaurant,
                  isSelected: initialType == OrderType.dineIn,
                ),
                _OrderTypeButton(
                  type: OrderType.parcel,
                  icon: Icons.takeout_dining,
                  isSelected: initialType == OrderType.parcel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTypeButton extends StatelessWidget {
  final OrderType type;
  final IconData icon;
  final bool isSelected;

  const _OrderTypeButton({
    required this.type,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                type.displayName,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
