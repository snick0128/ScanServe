import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import '../models/guest_profile_model.dart';
import '../models/order_model.dart';

/// Customer Details Bottom Sheet
/// 
/// Reusable bottom sheet for collecting customer name and phone.
/// Used for bill requests and checkout.
/// Matches existing QR Menu UI design system.
class CustomerDetailsBottomSheet extends StatefulWidget {
  final GuestProfile? existingProfile;
  final OrderType orderType;
  final String title;
  final String submitButtonText;

  const CustomerDetailsBottomSheet({
    Key? key,
    this.existingProfile,
    this.orderType = OrderType.dineIn,
    this.title = 'Customer Details',
    this.submitButtonText = 'Confirm',
  }) : super(key: key);

  @override
  State<CustomerDetailsBottomSheet> createState() => _CustomerDetailsBottomSheetState();

  /// Show the bottom sheet and return the customer details
  static Future<GuestProfile?> show({
    required BuildContext context,
    GuestProfile? existingProfile,
    OrderType orderType = OrderType.dineIn,
    String title = 'Customer Details',
    String submitButtonText = 'Confirm',
  }) async {
    return await showModalBottomSheet<GuestProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomerDetailsBottomSheet(
        existingProfile: existingProfile,
        orderType: orderType,
        title: title,
        submitButtonText: submitButtonText,
      ),
    );
  }
}

class _CustomerDetailsBottomSheetState extends State<CustomerDetailsBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingProfile?.name ?? '');
    _phoneController = TextEditingController(text: widget.existingProfile?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Ionicons.close_circle_outline),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please provide your details for the bill',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Ionicons.person_outline),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: widget.orderType == OrderType.parcel
                          ? 'Phone Number *'
                          : 'Phone Number (Optional)',
                      hintText: '+91 9876543210',
                      helperText: widget.orderType == OrderType.parcel
                          ? 'Required for parcel orders'
                          : 'Optional for dine-in',
                      helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      prefixIcon: const Icon(Ionicons.call_outline),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      // Phone is required for parcel orders
                      if (widget.orderType == OrderType.parcel) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Phone number is required for parcel orders';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.submitButtonText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Create guest profile with entered details
      final profile = GuestProfile.create(
        guestId: widget.existingProfile?.guestId ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      Navigator.pop(context, profile);
    }
  }
}
