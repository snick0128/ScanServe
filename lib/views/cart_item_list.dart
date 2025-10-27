import 'package:flutter/material.dart';
import '../controllers/cart_controller.dart';
import 'shimmer_loading.dart';

import 'package:flutter/material.dart';

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
          elevation: 4,
          shadowColor: Colors.deepPurple.withOpacity(0.15),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  if (item.item.imageUrl != null)
                    Container(
                      width: isMobile ? 60 : 70,
                      height: isMobile ? 60 : 70,
                      margin: EdgeInsets.only(right: isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(item.item.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: isMobile ? 60 : 70,
                      height: isMobile ? 60 : 70,
                      margin: EdgeInsets.only(right: isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: isMobile ? 24 : 28,
                      ),
                    ),

                  // Item details section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name
                        Text(
                          item.item.name,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),

                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withAlpha(10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '₹${item.item.price.toStringAsFixed(2)} each',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: isMobile ? 16 : 20),

                  // Quantity + Total price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple.withAlpha(30),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AnimatedIconButton(
                              icon: Icons.remove,
                              color: item.quantity > 1
                                  ? Colors.deepPurple
                                  : Colors.grey[400]!,
                              onPressed: () {
                                onUpdateQuantity(
                                  item.item.id,
                                  item.quantity - 1,
                                );
                              },
                              isMobile: isMobile,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 14 : 16,
                                vertical: isMobile ? 8 : 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.quantity.toString(),
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            _AnimatedIconButton(
                              icon: Icons.add,
                              color: Colors.deepPurple,
                              onPressed: () {
                                onUpdateQuantity(
                                  item.item.id,
                                  item.quantity + 1,
                                );
                              },
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isMobile ? 12 : 16),

                      // Total price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${item.totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
