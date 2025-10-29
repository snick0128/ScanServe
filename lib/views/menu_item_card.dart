import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tenant_model.dart';
import '../controllers/cart_controller.dart';
import 'menu_item_preview.dart';

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

  void _showItemPreview() {
    MenuItemPreview.show(
      context: context,
      item: widget.item,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(
      builder: (context, cartController, _) {
        final isInCart = cartController.isItemInCart(widget.item.id);
        final quantity = cartController.getItemQuantity(widget.item.id);

        return GestureDetector(
          onTap: _showItemPreview,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Card(
                    elevation: _isHovered ? 12 : 6,
                    shadowColor: Colors.black.withAlpha(80),
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        24,
                      ), // Increased from 16 to 24 for better separation
                      side: BorderSide(color: Colors.grey.shade200, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.item.imageUrl != null)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(
                                  24,
                                ), // Match the card's border radius
                              ),
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
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '₹${widget.item.price.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFF6E40),
                                          fontSize: 12,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (isInCart)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 100,
                                      ),
                                      child: _QuantityControls(
                                        itemId: widget.item.id,
                                        quantity: quantity,
                                        onUpdateQuantity:
                                            cartController.updateQuantity,
                                        isHovered: _isHovered,
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 30,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF914D),
                                            Color(0xFFFF6E40),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _isHovered
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFFF6E40,
                                                  ).withAlpha(80),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _onAddPressed,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.add_shopping_cart,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Add',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ],
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
                      ],
                    ),
                  ),
                );
              },
            ),
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
    Key? key,
    required this.itemId,
    required this.quantity,
    required this.onUpdateQuantity,
    required this.isHovered,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If quantity is 0, return null to show the Add button
    if (quantity <= 0) {
      // Use a post-frame callback to ensure we're not updating state during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onUpdateQuantity(itemId, 0); // Notify parent to remove the item
      });
      return const SizedBox.shrink();
    }

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isHovered
            ? const Color(0xFFFF6E40).withAlpha(15)
            : Colors.grey[50],
        border: Border.all(color: const Color(0xFFFF6E40).withAlpha(50)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (quantity > 1) {
                onUpdateQuantity(itemId, quantity - 1);
              } else {
                // If quantity is 1, set to 0 to trigger removal
                onUpdateQuantity(itemId, 0);
              }
            },
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: Icon(
                Icons.remove,
                color: quantity > 0
                    ? const Color(0xFFFF6E40)
                    : Colors.grey[400],
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            constraints: const BoxConstraints(minWidth: 16),
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF6E40),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onUpdateQuantity(itemId, quantity + 1),
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: Color(0xFFFF6E40), size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
