import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tenant_model.dart';
import '../controllers/cart_controller.dart';

class MenuItemCard extends StatefulWidget {
  final MenuItem item;
  final VoidCallback onAddPressed;

  const MenuItemCard({Key? key, required this.item, required this.onAddPressed})
    : super(key: key);

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    widget.onAddPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(
      builder: (context, cartController, child) {
        final isInCart = cartController.isItemInCart(widget.item.id);
        final quantity = cartController.getItemQuantity(widget.item.id);

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Card(
                  elevation: _isHovered ? 8 : 5,
                  shadowColor: Colors.black.withAlpha(30),
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.item.imageUrl != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            widget.item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[100],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.item.description,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${widget.item.price.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF6E40),
                                  ),
                                ),
                                if (isInCart)
                                  _QuantityControls(
                                    itemId: widget.item.id,
                                    quantity: quantity,
                                    onUpdateQuantity: cartController.updateQuantity,
                                    isHovered: _isHovered,
                                  )
                                else
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF914D),
                                          Color(0xFFFF6E40),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                                      boxShadow: _isHovered
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFFFF6E40).withAlpha(50),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _onAddPressed,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final String itemId;
  final int quantity;
  final Function(String, int) onUpdateQuantity;
  final bool isHovered;

  const _QuantityControls({
    required this.itemId,
    required this.quantity,
    required this.onUpdateQuantity,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isHovered ? const Color(0xFFFF6E40).withAlpha(15) : Colors.grey[50],
        border: Border.all(color: const Color(0xFFFF6E40).withAlpha(50)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 18,
            padding: const EdgeInsets.all(6),
            icon: Icon(
              Icons.remove,
              color: quantity > 1 ? const Color(0xFFFF6E40) : Colors.grey[400],
            ),
            onPressed: quantity > 1
                ? () => onUpdateQuantity(itemId, quantity - 1)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6E40).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6E40),
              ),
            ),
          ),
          IconButton(
            iconSize: 18,
            padding: const EdgeInsets.all(6),
            icon: const Icon(
              Icons.add,
              color: Color(0xFFFF6E40),
            ),
            onPressed: () => onUpdateQuantity(itemId, quantity + 1),
          ),
        ],
      ),
    );
  }
}
