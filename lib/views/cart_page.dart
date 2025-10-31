import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/models/order_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_details.dart';
import '../services/order_service.dart';
import '../services/guest_session_service.dart';
import 'previous_orders_list.dart';
import 'cart_item_list.dart';
import '../utils/snackbar_helper.dart';

class CartPage extends StatefulWidget {
  final String tenantId;

  const CartPage({Key? key, required this.tenantId}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Local state for item notes
  final Map<String, String> _itemNotes = {};

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();
    final cartController = context.watch<CartController>();
    final orderService = OrderService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Order',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        elevation: 2,
        shadowColor: Colors.deepPurple.withOpacity(0.1),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
                  // Previous orders for dine-in
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
                    Divider(thickness: 1, height: 1, color: Colors.grey[300]),
                  ],

                  // Current cart items with notes
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

                  // Order summary
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
  final List items;
  final Function(dynamic, int) onUpdateQuantity;
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

  void _showNoteBottomSheet(BuildContext context, dynamic item) {
    final itemId = item.id ?? item.hashCode.toString();
    final currentNote = itemNotes[itemId] ?? '';
    final noteController = TextEditingController(text: currentNote);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        color: Colors.deepPurple,
                        size: isMobile ? 24 : 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add Chef Note',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Special instructions for ${item.name ?? "this item"}',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Text field
                  TextField(
                    controller: noteController,
                    autofocus: true,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'e.g., Extra spicy, no onions...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: isMobile ? 14 : 15,
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.light
                          ? Colors.grey[50]
                          : Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: TextStyle(fontSize: isMobile ? 14 : 15),
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 14 : 16,
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
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
                            padding: EdgeInsets.symmetric(
                              vertical: isMobile ? 14 : 16,
                            ),
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save Note',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
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
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final itemId = item.id ?? item.hashCode.toString();
        final hasNote = itemNotes.containsKey(itemId);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name ?? 'Item',
                            style: TextStyle(
                              fontSize: isMobile ? 15 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${(item.price ?? 0).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quantity controls
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            iconSize: isMobile ? 18 : 20,
                            onPressed: () {
                              final currentQty = item.quantity ?? 1;
                              onUpdateQuantity(item, currentQty - 1);
                            },
                            padding: EdgeInsets.all(isMobile ? 4 : 8),
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity ?? 1}',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            iconSize: isMobile ? 18 : 20,
                            onPressed: () {
                              final currentQty = item.quantity ?? 1;
                              onUpdateQuantity(item, currentQty + 1);
                            },
                            padding: EdgeInsets.all(isMobile ? 4 : 8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Note button and display
                const SizedBox(height: 8),
                if (hasNote)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Colors.amber[800],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            itemNotes[itemId]!,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.amber[900],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showNoteBottomSheet(context, item),
                    icon: Icon(
                      hasNote ? Icons.edit_note : Icons.note_add_outlined,
                      size: isMobile ? 16 : 18,
                    ),
                    label: Text(
                      hasNote ? 'Edit Note' : 'Add Note',
                      style: TextStyle(fontSize: isMobile ? 12 : 13),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
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
            height: isMobile ? 120 : 140,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        final settings = snapshot.data ?? {};
        final taxRate = settings['taxRate'] as double? ?? 0.18;
        final tax = subtotal * taxRate;
        final total = subtotal + tax;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 16 : 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -8),
                spreadRadius: 2,
              ),
            ],
            borderRadius: isMobile
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : BorderRadius.zero,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subtotal
                _buildSummaryRow(
                  'Subtotal',
                  '₹${subtotal.toStringAsFixed(2)}',
                  false,
                ),
                SizedBox(height: isMobile ? 6 : 8),
                // Tax
                _buildSummaryRow(
                  'Tax (${(taxRate * 100).toStringAsFixed(0)}%)',
                  '₹${tax.toStringAsFixed(2)}',
                  false,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[300],
                  ),
                ),
                // Total
                _buildSummaryRow('Total', '₹${total.toStringAsFixed(2)}', true),
                SizedBox(height: isMobile ? 16 : 20),
                // Action buttons
                if (orderController.currentOrderType == OrderType.dineIn)
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          context: context,
                          text: 'Send to Kitchen',
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.orangeAccent],
                          ),
                          shadowColor: Colors.orange,
                          isEnabled: cartController.itemCount > 0,
                          isMobile: isMobile,
                          fontSize: isMobile ? 13 : 14,
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
                      SizedBox(width: isMobile ? 10 : 12),
                      Expanded(
                        child: _buildButton(
                          context: context,
                          text: 'Pay Now',
                          gradient: const LinearGradient(
                            colors: [
                              Colors.deepPurple,
                              Colors.deepPurpleAccent,
                            ],
                          ),
                          shadowColor: Colors.deepPurple,
                          isEnabled: subtotal > 0,
                          isMobile: isMobile,
                          fontSize: isMobile ? 13 : 14,
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
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                    ),
                    shadowColor: Colors.deepPurple,
                    isEnabled: subtotal > 0,
                    isMobile: isMobile,
                    fontSize: isMobile ? 15 : 16,
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
            fontSize: isBold ? (isMobile ? 17 : 19) : (isMobile ? 14 : 15),
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? (isMobile ? 18 : 20) : (isMobile ? 14 : 15),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? Colors.deepPurple : Colors.black87,
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
    required LinearGradient gradient,
    required Color shadowColor,
    required bool isEnabled,
    required bool isMobile,
    required VoidCallback onPressed,
    double fontSize = 16,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled ? gradient : null,
        color: isEnabled ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: shadowColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 14 : 16,
              horizontal: isMobile ? 16 : 24,
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.white : Colors.grey[500],
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
