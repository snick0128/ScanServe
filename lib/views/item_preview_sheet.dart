import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/tenant_model.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_helper.dart';
import '../controllers/cart_controller.dart';
import '../utils/snackbar_helper.dart';
import '../utils/session_validator.dart';
import '../app.dart';
import '../config/app_config.dart';

class ItemPreviewSheet extends StatefulWidget {
  final MenuItem item;
  final VoidCallback onAdd;

  const ItemPreviewSheet({
    Key? key,
    required this.item,
    required this.onAdd,
  }) : super(key: key);

  @override
  State<ItemPreviewSheet> createState() => _ItemPreviewSheetState();
}

class _ItemPreviewSheetState extends State<ItemPreviewSheet> {
  Variant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    // REQUIREMENT 8: Do not auto-select first variant silently. Force explicit user action.
  }

  @override
  Widget build(BuildContext context) {
    // Determine price to show
    final displayPrice = _selectedVariant?.price ?? widget.item.price;
    final bool isVariantRequired = widget.item.hasVariants && _selectedVariant == null;

    return Container(
      // We wrap in a Stack so we can have the floating close button
      // Use a fixed or constrained height to match bottom sheet behavior
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main Sheet Content
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large Food Image
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              widget.item.imageUrl ?? 'https://via.placeholder.com/400x300',
                              width: double.infinity,
                              height: 280,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 280,
                                color: Colors.grey[200],
                                child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),

                        // Item Details Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tags
                              Row(
                                children: [
                                  // Veg/Non-Veg Icon
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: widget.item.isVeg ? const Color(0xFF0F6D3F) : Colors.red, width: 1),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: widget.item.isVeg ? const Color(0xFF0F6D3F) : Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (widget.item.isBestseller) ...[
                                    _buildTag('Bestseller', const Color(0xFFE6F4EC), const Color(0xFF0F6D3F)),
                                    const SizedBox(width: 8),
                                  ],
                                  _buildTag('New', const Color(0xFFFFF4E6), const Color(0xFFE67E22)),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Item Name
                              Text(
                                widget.item.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),

                              const SizedBox(height: 4),

                              // Price
                              Text(
                                '₹${displayPrice.toInt()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Description
                              Text(
                                widget.item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                              
                              // Variants Selection
                              if (widget.item.hasVariants) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Select Portion / Variant',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1C1C1E),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...widget.item.variants.map((v) => _buildVariantOption(v)),
                              ],
                              
                              const SizedBox(height: 100), // Reserve space for footer
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom CTA Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: isVariantRequired
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[600]!],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF0F6D3F), Color(0xFF0B522F)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isVariantRequired ? Colors.grey : const Color(0xFF0F6D3F)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isVariantRequired ? null : () async {
                      HapticHelper.medium();
                      try {
                        if (widget.item.hasVariants) {
                          if (_selectedVariant != null) {
                            context.read<CartController>().addItem(widget.item, _selectedVariant);
                            SnackbarHelper.showTopSnackBar(
                              context,
                              '${widget.item.name} (${_selectedVariant!.name}) added to cart',
                              duration: const Duration(seconds: 1),
                            );
                          }
                        } else {
                          widget.onAdd();
                        }
                        Navigator.pop(context);
                      } catch (e) {
                        final cart = context.read<CartController>();
                        final validation = SessionValidator.validateForCart(
                          tenantId: cart.tenantId,
                          tableId: cart.tableId,
                          isParcelOrder: cart.isParcelOrder,
                        );
                        
                        if (!validation.isValid) {
                          SessionValidator.showValidationDialog(
                            context: context,
                            result: validation,
                            onScanQR: () => Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => Initializer(config: AppConfig.init())),
                              (route) => false,
                            ),
                          );
                        } else {
                          SnackbarHelper.showTopSnackBar(context, 'Error: $e');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: Text(
                        isVariantRequired 
                          ? 'PLEASE SELECT A VARIANT'
                          : 'ADD TO PLATE - ₹${displayPrice.toInt()}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating Close Button Above the Sheet
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticHelper.light();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.black, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantOption(Variant variant) {
    final isSelected = _selectedVariant?.name == variant.name;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedVariant = variant);
        HapticHelper.light();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF2FDF7) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F6D3F) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                variant.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0F6D3F) : Colors.black,
                ),
              ),
            ),
            Text(
              '₹${variant.price.toInt()}',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF0F6D3F) : Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F6D3F) : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF0F6D3F) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(child: Icon(Icons.check, size: 14, color: Colors.white))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
