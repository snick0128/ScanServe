import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scan_serve/models/order_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_details.dart';
import '../services/order_service.dart';
import '../services/guest_session_service.dart';
import 'previous_orders_list.dart';
import '../utils/snackbar_helper.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_helper.dart';
import 'payment_page.dart';

class CartPage extends StatefulWidget {
  final String tenantId;
  final VoidCallback? onBack;
  final VoidCallback? onOrderPlaced;

  const CartPage({Key? key, required this.tenantId, this.onBack, this.onOrderPlaced}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();
    final cartController = context.watch<CartController>();
    final orderService = OrderService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: false, // Prevent the main screen from jumping when keyboard opens
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: orderService.getTenantSettings(widget.tenantId),
          builder: (context, snapshot) {
            final name = snapshot.data?['name'] ?? 'Restaurant';
            return Text(
              name,
              style: GoogleFonts.outfit(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 600;
          final isTablet = screenWidth >= 600 && screenWidth < 1200;
          final isDesktop = screenWidth >= 1200;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1200 : (isTablet ? 800 : screenWidth),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (cartController.items.isNotEmpty && orderController.currentOrderType == OrderType.dineIn) ...[
                            StreamBuilder<List<OrderDetails>>(
                              stream: orderService.getTableOrders(
                                widget.tenantId,
                                orderController.currentSession?.tableId ?? '',
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 100,
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                final orders = snapshot.data!;
                                return PreviousOrdersList(
                                  orders: orders,
                                  isMobile: isMobile,
                                  isTablet: isTablet,
                                );
                              },
                            ),
                            const Divider(height: 1, color: AppTheme.borderColor),
                          ],
                          _CartItemsWithNotes(
                            key: ValueKey(cartController.items.length),
                            items: cartController.items,
                            onUpdateQuantity: (item, newQuantity) {
                              HapticHelper.light();
                              final key = cartController.getCartKey(item.item.id, item.selectedVariant);
                              if (newQuantity <= 0) {
                                cartController.removeItem(key);
                              } else {
                                cartController.updateQuantity(
                                  key,
                                  newQuantity,
                                );
                              }
                            },
                            onNoteUpdate: (item, note) {
                              final key = cartController.getCartKey(item.item.id, item.selectedVariant);
                              cartController.updateNote(key, note);
                            },
                            isMobile: isMobile,
                            isTablet: isTablet,
                          ),
                          if (cartController.items.isNotEmpty)
                            _BillDetails(
                              subtotal: cartController.totalAmount,
                              tenantId: widget.tenantId,
                              isMobile: isMobile,
                              isTablet: isTablet,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (cartController.items.isNotEmpty)
                    _CartActionFooter(
                      subtotal: cartController.totalAmount,
                      tenantId: widget.tenantId,
                      cartController: cartController,
                      onOrderPlaced: widget.onOrderPlaced,
                      isMobile: isMobile,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CartItemsWithNotes extends StatelessWidget {
  final List<CartItem> items;
  final Function(CartItem, int) onUpdateQuantity;
  final Function(CartItem, String) onNoteUpdate;
  final bool isMobile;
  final bool isTablet;

  const _CartItemsWithNotes({
    Key? key,
    required this.items,
    required this.onUpdateQuantity,
    required this.onNoteUpdate,
    required this.isMobile,
    required this.isTablet,
  }) : super(key: key);

  void _showNoteBottomSheet(BuildContext context, CartItem item) {
    final currentNote = item.note ?? '';
    final noteController = TextEditingController(text: currentNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Chef Note',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.item.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 150,
                  style: TextStyle(color: AppTheme.primaryText),
                  decoration: InputDecoration(
                    hintText: 'e.g., Extra spicy, no onions, well done...',
                    hintStyle: TextStyle(
                      color: AppTheme.secondaryText.withOpacity(0.5),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: AppTheme.searchBarBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          onNoteUpdate(item, noteController.text.trim());
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Note',
                          style: TextStyle(
                            fontSize: 16,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.searchBarBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: AppTheme.secondaryText.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from the menu to get started',
              style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        final itemId = item.item.id;
        final hasNote = item.note != null && item.note!.isNotEmpty;
        final imageSize = isMobile ? 70.0 : 80.0;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ... rest of the existing item card logic ...
              // (I will just copy the content correctly in the final tool call)
              Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Hero(
                      tag: 'cart_item_${item.item.id}',
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child:
                              item.item.imageUrl != null &&
                                  item.item.imageUrl!.isNotEmpty
                              ? Image.network(
                                  item.item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholder();
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.white.withOpacity(0.05),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        );
                                      },
                                )
                              : _buildPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name and quantity controls row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.item.name,
                                      style: TextStyle(
                                        fontSize: isMobile ? 15 : 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryText,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.selectedVariant != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          item.selectedVariant!.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Horizontal Quantity controls
                              Container(
                                height: 36, // Increased height
                                decoration: BoxDecoration(
                                  color: AppTheme.searchBarBackground,
                                  borderRadius: BorderRadius.circular(12), // Smoother radius
                                  border: Border.all(
                                    color: AppTheme.borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          onUpdateQuantity(
                                            item,
                                            item.quantity - 1,
                                          );
                                        },
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              left: Radius.circular(11),
                                            ),
                                        child: Container(
                                          width: 36, // Larger width
                                          height: 36,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            item.quantity > 1
                                                ? Icons.remove
                                                : Icons.delete_outline,
                                            size: 18,
                                            color: item.quantity > 1
                                                ? AppTheme.primaryColor
                                                : Colors.red[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20, // Smaller separator height
                                      color: AppTheme.borderColor,
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryText,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: AppTheme.borderColor,
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          onUpdateQuantity(
                                            item,
                                            item.quantity + 1,
                                          );
                                        },
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                              right: Radius.circular(11),
                                            ),
                                        child: Container(
                                          width: 36, // Larger width
                                          height: 36,
                                          alignment: Alignment.center,
                                          child: Icon(
                                            Icons.add,
                                            size: 18,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (item.item.description != null &&
                              item.item.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.item.description!,
                              style: TextStyle(
                                  fontSize: isMobile ? 12 : 13,
                                  color: AppTheme.secondaryText,
                                  height: 1.3,
                                ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Price breakdown: ₹80 × 2 = ₹160
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryText,
                              ),
                              children: [
                                TextSpan(text: '₹${(item.selectedVariant?.price ?? item.item.price).toStringAsFixed(2)}'),
                                TextSpan(
                                  text: ' × ${item.quantity}',
                                  style: const TextStyle(
                                    color: AppTheme.secondaryText,
                                    fontSize: 14,
                                  ),
                                ),
                                const TextSpan(text: ' = '),
                                TextSpan(
                                  text: '₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Note section
              if (hasNote)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber[200]!, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.sticky_note_2,
                        size: 16,
                        color: Colors.amber[800],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Note button
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.borderColor, width: 1),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showNoteBottomSheet(context, item),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            hasNote ? Icons.edit_note : Icons.note_add_outlined,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasNote ? 'Edit Note' : 'Add Note for Chef',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
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
        );
      }).toList(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: Center(
        child: Icon(Icons.restaurant, size: 40, color: Colors.white10),
      ),
    );
  }
}

class _BillDetails extends StatelessWidget {
  final double subtotal;
  final String tenantId;
  final bool isMobile;
  final bool isTablet;

  const _BillDetails({
    Key? key,
    required this.subtotal,
    required this.tenantId,
    this.isMobile = false,
    this.isTablet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();

    return FutureBuilder<Map<String, dynamic>>(
      future: orderService.getTenantSettings(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final settings = snapshot.data ?? {};
        final taxRate = (settings['taxRate'] as num?)?.toDouble() ?? 0.05;
        final tax = subtotal * taxRate;
        final total = subtotal + tax;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'BILL DETAILS',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}', false),
              const SizedBox(height: 8),
              _buildSummaryRow('GST', '₹${tax.toStringAsFixed(2)}', false, isGST: true),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE5E5EA), thickness: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(1)}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF8E8E93)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Orders once placed cannot be cancelled and are non-refundable.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF8E8E93),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40), // Extra space at bottom of scroll
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isBold, {bool isGST = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            if (isGST) ...[
              const SizedBox(width: 4),
              const Icon(Icons.info_outline, size: 14, color: Color(0xFF8E8E93)),
            ],
          ],
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF1C1C1E),
          ),
        ),
      ],
    );
  }
}

class _CartActionFooter extends StatelessWidget {
  final double subtotal;
  final String tenantId;
  final CartController cartController;
  final VoidCallback? onOrderPlaced;
  final bool isMobile;

  const _CartActionFooter({
    Key? key,
    required this.subtotal,
    required this.tenantId,
    required this.cartController,
    this.onOrderPlaced,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderController = context.read<OrderController>();
    final orderService = OrderService();
    final guestSession = GuestSessionService();

    return FutureBuilder<Map<String, dynamic>>(
      future: orderService.getTenantSettings(tenantId),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? {};
        final taxRate = (settings['taxRate'] as num?)?.toDouble() ?? 0.05;
        final total = subtotal * (1 + taxRate);

        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: orderController.currentOrderType == OrderType.dineIn
              ? Row(
                  children: [
                    Expanded(
                      flex: 40,
                      child: _buildButton(
                        text: 'Pay',
                        isPrimary: false,
                        onPressed: () {
                          HapticHelper.medium();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentPage(tenantId: tenantId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 60,
                      child: _buildButton(
                        text: 'Place Order',
                        isPrimary: true,
                        total: total,
                        onPressed: () async {
                          HapticHelper.medium();
                          final guestId = await guestSession.getGuestId();
                          await orderService.createOrder(
                            tenantId: tenantId,
                            guestId: guestId,
                            orderType: OrderType.dineIn,
                            tableId: orderController.currentSession?.tableId,
                            cartItems: cartController.items,
                            chefNote: _buildNotesString(cartController),
                          );
                          cartController.clear();
                          if (onOrderPlaced != null) {
                            onOrderPlaced!();
                          } else if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                )
              : _buildButton(
                  text: 'Pay Securely',
                  isPrimary: true,
                  total: total,
                  onPressed: () {
                    HapticHelper.medium();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(tenantId: tenantId),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  String _buildNotesString(CartController cart) {
    final itemsWithNotes = cart.items.where((i) => i.note != null && i.note!.isNotEmpty);
    if (itemsWithNotes.isEmpty) return 'Sent to kitchen - payment pending';
    return 'Sent to kitchen - payment pending. Chef notes: ' +
        itemsWithNotes.map((i) => 'Item ${i.item.name}: ${i.note}').join('; ');
  }

  Widget _buildButton({
    required String text,
    required bool isPrimary,
    double? total,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: isPrimary ? null : Colors.white,
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF0F6D3F), Color(0xFF0B522F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: isPrimary ? null : Border.all(color: const Color(0xFFE5E5EA)),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF0F6D3F).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: total != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            text,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' • ₹${total.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.outfit(
                      color: isPrimary ? Colors.white : const Color(0xFF1C1C1E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
