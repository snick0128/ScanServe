import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tenant_model.dart';
import '../controllers/cart_controller.dart';
import 'item_preview_sheet.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_helper.dart';

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
    HapticHelper.medium();
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    if (widget.item.hasVariants) {
      _showItemPreview();
    } else {
      widget.onAddPressed();
    }
  }

  void _showItemPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemPreviewSheet(
        item: widget.item,
        onAdd: widget.onAddPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = context.watch<CartController>();
    final quantity = cartController.getItemQuantity(widget.item.id);
    final isInCart = quantity > 0 && !widget.item.hasVariants;

    return InkWell(
      onTap: _showItemPreview,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with 10px Top, Left, Right padding
            Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      height: constraints.maxWidth * 0.74, // Slightly taller for richer card fill
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.item.imageUrl != null
                            ? Image.network(
                                widget.item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: const Color(0xFFF2F2F7)),
                              )
                            : Container(color: const Color(0xFFF2F2F7)),
                      ),
                    );
                  }
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 0,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.18),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Veg/Non-veg indicator overlay
                Positioned(
                  top: 18, // Adjusted for 10px top padding
                  left: 18, // Adjusted for 10px left padding
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: widget.item.isVeg ? const Color(0xFF0F6D3F) : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.fiber_manual_record,
                      color: widget.item.isVeg ? const Color(0xFF0F6D3F) : Colors.red,
                      size: 8,
                    ),
                  ),
                ),
              ],
            ),
  
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10), // Uniform 10px padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tags
                    Row(
                      children: [
                        if (widget.item.isBestseller)
                          _buildTag('Bestseller', AppTheme.lightGreen, AppTheme.starGreen)
                        else if (widget.item.isVeg)
                          _buildTag('Veg', AppTheme.lightGreen, AppTheme.primaryColor)
                        else
                          _buildTag('Non-Veg', AppTheme.lightOrange, Colors.red),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.item.name,
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.description,
                      style: GoogleFonts.outfit(
                        color: AppTheme.secondaryText,
                        fontSize: 12.5,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '₹${widget.item.price.toInt()}',
                            style: GoogleFonts.outfit(
                              color: AppTheme.primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isInCart)
                          Padding(
                            padding: const EdgeInsets.only(left: 8), // Reduced padding
                            child: _QuantityControls(
                              itemId: widget.item.id,
                              quantity: quantity,
                              onUpdateQuantity: (id, q) => cartController.updateQuantity(id, q),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _buildAddButton(),
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
  }

  Widget _buildTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      height: 38, // Increased from 32 for better touch target (Requirement #9)
      width: 80,  // Slightly wider
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: _onAddPressed,
        child: Center(
          child: Text(
            widget.item.hasVariants ? 'SELECT' : 'ADD',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final String itemId;
  final int quantity;
  final Function(String, int) onUpdateQuantity;

  const _QuantityControls({
    required this.itemId,
    required this.quantity,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38, // Increased height for better tap area
      width: 90,  // Increased width
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBtn(Icons.remove, () => onUpdateQuantity(itemId, quantity - 1)),
          Text(
            '$quantity',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildBtn(Icons.add, () => onUpdateQuantity(itemId, quantity + 1)),
        ],
      ),
    );
  }

  Widget _buildBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticHelper.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 38,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
