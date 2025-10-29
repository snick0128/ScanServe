import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/controllers/cart_controller.dart';
import 'package:scan_serve/models/tenant_model.dart';

class MenuItemPreview extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onClose;
  final VoidCallback onAddToCart;
  final bool isInCart;
  final int quantity;
  final Function(String, int) onUpdateQuantity;

  const MenuItemPreview({
    Key? key,
    required this.item,
    required this.onClose,
    required this.onAddToCart,
    required this.isInCart,
    required this.quantity,
    required this.onUpdateQuantity,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required MenuItem item,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<CartController>(
        builder: (context, cartController, _) {
          final isInCart = cartController.isItemInCart(item.id);
          final quantity = cartController.getItemQuantity(item.id);
          
          return MenuItemPreview(
            item: item,
            onClose: () => Navigator.of(context).pop(),
            onAddToCart: () => cartController.addItem(item),
            isInCart: isInCart,
            quantity: quantity,
            onUpdateQuantity: (itemId, newQuantity) {
              cartController.updateQuantity(itemId, newQuantity);
              if (newQuantity <= 0) {
                Navigator.of(context).pop();
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Item image
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(
              bottom: 16 + bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFFF6E40),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 24),
                if (isInCart)
                  _buildQuantityControls(context)
                else
                  _buildAddButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onAddToCart,
        child: Container(
          height: 36,
          width: MediaQuery.of(context).size.width - 100, // Leave 50px on each side
          decoration: BoxDecoration(
            color: const Color(0xFFFF6E40),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6E40).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Add to Cart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Center(
      child: Container(
        height: 36,
        width: MediaQuery.of(context).size.width - 100, // Leave 50px on each side
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF6E40).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => onUpdateQuantity(item.id, quantity - 1),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6E40).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: Color(0xFFFF6E40),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              '$quantity',
              style: const TextStyle(
                color: Color(0xFFFF6E40),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: () => onUpdateQuantity(item.id, quantity + 1),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6E40).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: Color(0xFFFF6E40),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
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
