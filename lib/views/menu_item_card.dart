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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
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
                    mainAxisSize: MainAxisSize.min, // Prevent column from expanding unnecessarily
                    children: [
                      if (widget.item.imageUrl != null)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect( // Ensure image doesn't overflow
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                        ),
                      Flexible( // Allow content to flex within constraints
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            12.0,
                            12.0,
                            12.0,
                            10.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.item.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.item.description,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '₹${widget.item.price.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFF6E40),
                                        ),
                                  ),
                                  if (isInCart)
                                    SizedBox(
                                      width: 65,
                                      child: _QuantityControls(
                                        itemId: widget.item.id,
                                        quantity: quantity,
                                        onUpdateQuantity:
                                            cartController.updateQuantity,
                                        isHovered: _isHovered,
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: 65,
                                      child: AnimatedContainer(
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
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(20),
                                          ),
                                          boxShadow: _isHovered
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFFFF6E40,
                                                    ).withAlpha(50),
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
                                              borderRadius: BorderRadius.circular(
                                                20,
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Add',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
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
      height: 32, // Fixed height for consistent centering
      decoration: BoxDecoration(
        color: isHovered
            ? const Color(0xFFFF6E40).withAlpha(15)
            : Colors.grey[50],
        border: Border.all(color: const Color(0xFFFF6E40).withAlpha(50)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 12,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: Icon(
              Icons.remove,
              color: quantity > 1 ? const Color(0xFFFF6E40) : Colors.grey[400],
            ),
            onPressed: quantity > 1
                ? () => onUpdateQuantity(itemId, quantity - 1)
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6E40),
              ),
            ),
          ),
          IconButton(
            iconSize: 12,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: const Icon(Icons.add, color: Color(0xFFFF6E40)),
            onPressed: () => onUpdateQuantity(itemId, quantity + 1),
          ),
        ],
      ),
    );
  }
}
