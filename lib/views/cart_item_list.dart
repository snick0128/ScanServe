import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';

class CartItemList extends StatelessWidget {
  final List<CartItem> items;
  final Function(String, int) onUpdateQuantity;
  final bool isMobile;
  final bool isTablet;

  const CartItemList({
    Key? key,
    required this.items,
    required this.onUpdateQuantity,
    this.isMobile = false,
    this.isTablet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(isMobile ? 32 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: isMobile ? 64 : 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'Add some items from the menu to get started!',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemHeight = isMobile ? 80.0 : 90.0;
        final imageSize = isMobile ? 60.0 : 70.0;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              if (item.item.imageUrl != null)
                Container(
                  width: imageSize,
                  height: imageSize,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(item.item.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: imageSize,
                  height: imageSize,
                  margin: EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),

              // Item name
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    item.item.name,
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // Quantity controls
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () => onUpdateQuantity(
                        item.item.id,
                        item.quantity - 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => onUpdateQuantity(
                        item.item.id,
                        item.quantity + 1,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Price
              Container(
                width: 80,
                padding: EdgeInsets.only(left: 12, right: 4),
                child: Text(
                  '₹${(item.item.price * item.quantity).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      );
      },
    );
  }
}
