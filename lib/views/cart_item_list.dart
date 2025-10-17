import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import 'shimmer_loading.dart';

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
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          elevation: 3,
          shadowColor: Colors.black.withAlpha(25),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: [
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.item.name,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: isMobile ? 2 : 4),
                      Text(
                        '₹${item.item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedIconButton(
                        icon: Icons.remove,
                        color: const Color(0xFFFF6E40),
                        onPressed: () {
                          onUpdateQuantity(item.item.id, item.quantity - 1);
                        },
                        isMobile: isMobile,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 8 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6E40).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.quantity.toString(),
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF6E40),
                          ),
                        ),
                      ),
                      _AnimatedIconButton(
                        icon: Icons.add,
                        color: const Color(0xFFFF6E40),
                        onPressed: () {
                          onUpdateQuantity(item.item.id, item.quantity + 1);
                        },
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ),

                // Item total
                SizedBox(width: isMobile ? 12 : 16),
                SizedBox(
                  width: isMobile ? 70 : 80,
                  child: Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6E40),
                    ),
                    textAlign: TextAlign.end,
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

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isMobile;

  const _AnimatedIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isMobile = false,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: IconButton(
              iconSize: widget.isMobile ? 20 : 24,
              padding: EdgeInsets.all(widget.isMobile ? 8 : 12),
              icon: Icon(widget.icon, color: widget.color),
              onPressed: widget.onPressed,
            ),
          );
        },
      ),
    );
  }
}
