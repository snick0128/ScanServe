import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/models/order_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_details.dart';
import '../services/order_service.dart';
import '../services/guest_session_service.dart';
import 'previous_orders_list.dart';
import '../utils/snackbar_helper.dart';

class CartPage extends StatefulWidget {
  final String tenantId;

  const CartPage({Key? key, required this.tenantId}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Map<String, String> _itemNotes = {};

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();
    final cartController = context.watch<CartController>();
    final orderService = OrderService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Your Order',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        centerTitle: false,
        actions: [
          if (cartController.itemCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${cartController.itemCount} items',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
                  if (orderController.currentOrderType == OrderType.dineIn) ...[
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
                    Container(height: 8, color: const Color(0xFFF5F7FA)),
                  ],
                  Expanded(
                    child: _CartItemsWithNotes(
                      key: ValueKey(cartController.items.length),
                      items: cartController.items,
                      onUpdateQuantity: (item, newQuantity) {
                        if (newQuantity <= 0) {
                          cartController.removeItem(item.item.id);
                        } else {
                          cartController.updateQuantity(
                            item.item.id,
                            newQuantity,
                          );
                        }
                      },
                      itemNotes: _itemNotes,
                      onNoteUpdate: (itemId, note) {
                        setState(() {
                          if (note.isEmpty) {
                            _itemNotes.remove(itemId);
                          } else {
                            _itemNotes[itemId] = note;
                          }
                        });
                      },
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ),
                  _OrderSummary(
                    subtotal: cartController.totalAmount,
                    tenantId: widget.tenantId,
                    cartController: cartController,
                    itemNotes: _itemNotes,
                    isMobile: isMobile,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
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
  final Map<String, String> itemNotes;
  final Function(String, String) onNoteUpdate;
  final bool isMobile;
  final bool isTablet;

  const _CartItemsWithNotes({
    Key? key,
    required this.items,
    required this.onUpdateQuantity,
    required this.itemNotes,
    required this.onNoteUpdate,
    required this.isMobile,
    required this.isTablet,
  }) : super(key: key);

  void _showNoteBottomSheet(BuildContext context, CartItem item) {
    final itemId = item.item.id;
    final currentNote = itemNotes[itemId] ?? '';
    final noteController = TextEditingController(text: currentNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView( // Ensure scrollable content
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.deepPurple,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add Chef Note',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.item.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Special instructions for ${item.item.name}',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: noteController,
                    autofocus: true,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'e.g., Extra spicy, no onions, well done...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
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
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
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
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            onNoteUpdate(itemId, noteController.text.trim());
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.deepPurple,
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
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from the menu to get started',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final itemId = item.item.id;
        final hasNote = itemNotes.containsKey(itemId);
        final imageSize = isMobile ? 70.0 : 80.0;

        return Container(
          margin: EdgeInsets.only(bottom: isMobile ? 12 : 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
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
                            color: const Color(0xFFE5E7EB),
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
                                          color: const Color(0xFFF5F7FA),
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
                                              color: Colors.deepPurple,
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
                                child: Text(
                                  item.item.name,
                                  style: TextStyle(
                                    fontSize: isMobile ? 15 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A1A),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Horizontal Quantity controls
                              Container(
                                height: 36, // Increased height
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(12), // Smoother radius
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
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
                                                ? Colors.deepPurple
                                                : Colors.red[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20, // Smaller separator height
                                      color: const Color(0xFFE5E7EB),
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
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: const Color(0xFFE5E7EB),
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
                                          child: const Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Colors.deepPurple,
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
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            '₹${(item.item.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.deepPurple,
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
                    color: Colors.amber[50],
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
                          itemNotes[itemId]!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[900],
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
                    top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
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
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasNote ? 'Edit Note' : 'Add Note for Chef',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
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
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: Icon(Icons.restaurant, size: 40, color: Colors.grey[400]),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final double subtotal;
  final String tenantId;
  final CartController cartController;
  final Map<String, String> itemNotes;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  const _OrderSummary({
    Key? key,
    required this.subtotal,
    required this.tenantId,
    required this.cartController,
    required this.itemNotes,
    this.isMobile = false,
    this.isTablet = false,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderService = OrderService();
    final orderController = context.read<OrderController>();
    final guestSession = GuestSessionService();

    return FutureBuilder<Map<String, dynamic>>(
      future: orderService.getTenantSettings(tenantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 140,
            alignment: Alignment.center,
            color: Colors.white,
            child: const CircularProgressIndicator(),
          );
        }

        final settings = snapshot.data ?? {};
        final taxRate = settings['taxRate'] as double? ?? 0.18;
        final tax = subtotal * taxRate;
        final total = subtotal + tax;

        return Container(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 20 : 24,
            isMobile ? 20 : 24,
            isMobile ? 20 : 24,
            isMobile ? 20 : 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price Breakdown',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Tap to view',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      _buildSummaryRow(
                        'Subtotal',
                        '₹${subtotal.toStringAsFixed(2)}',
                        false,
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Tax (${(taxRate * 100).toStringAsFixed(0)}%)',
                        '₹${tax.toStringAsFixed(2)}',
                        false,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[200]!,
                          Colors.grey[300]!,
                          Colors.grey[200]!,
                        ],
                      ),
                    ),
                  ),
                ),
                _buildSummaryRow('Total', '₹${total.toStringAsFixed(2)}', true),
                const SizedBox(height: 20),
                if (orderController.currentOrderType == OrderType.dineIn)
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          context: context,
                          text: 'Send to Kitchen',
                          colors: [Colors.orange[600]!, Colors.orange[400]!],
                          isEnabled: cartController.itemCount > 0,
                          isMobile: isMobile,
                          onPressed: () async {
                            if (!context.mounted) return;
                            try {
                              final guestId = await guestSession.getGuestId();
                              await orderService.createOrder(
                                tenantId: tenantId,
                                guestId: guestId,
                                orderType: orderController.currentOrderType,
                                tableId:
                                    orderController.currentSession?.tableId,
                                cartItems: cartController.items,
                                chefNote: _buildNotesString(),
                              );
                              cartController.clear();
                              if (!context.mounted) return;
                              SnackbarHelper.showTopSnackBar(
                                context,
                                'Order sent to kitchen!',
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              if (!context.mounted) return;
                              SnackbarHelper.showTopSnackBar(
                                context,
                                'Error: $e',
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildButton(
                          context: context,
                          text: 'Pay Now',
                          colors: [
                            Colors.deepPurple[700]!,
                            Colors.deepPurple[500]!,
                          ],
                          isEnabled: subtotal > 0,
                          isMobile: isMobile,
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/checkout',
                              arguments: {
                                'tenantId': tenantId,
                                'orderType': orderController.currentOrderType,
                                'tableId':
                                    orderController.currentSession?.tableId,
                                'requirePayment': true,
                                'itemNotes': itemNotes,
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  )
                else
                  _buildButton(
                    context: context,
                    text: 'Pay & Place Order',
                    colors: [Colors.deepPurple[700]!, Colors.deepPurple[500]!],
                    isEnabled: subtotal > 0,
                    isMobile: isMobile,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/checkout',
                        arguments: {
                          'tenantId': tenantId,
                          'orderType': orderController.currentOrderType,
                          'tableId': null,
                          'requirePayment': true,
                          'itemNotes': itemNotes,
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? const Color(0xFF1A1A1A) : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 20 : 16,
            fontWeight: FontWeight.w700,
            color: isBold ? Colors.deepPurple : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  String _buildNotesString() {
    if (itemNotes.isEmpty) return 'Sent to kitchen - payment pending';
    final notesText = itemNotes.entries
        .map((e) => 'Item ${e.key}: ${e.value}')
        .join('; ');
    return 'Sent to kitchen - payment pending. Chef notes: $notesText';
  }

  Widget _buildButton({
    required BuildContext context,
    required String text,
    required List<Color> colors,
    required bool isEnabled,
    required bool isMobile,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: colors[0].withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.white : Colors.grey[500],
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
