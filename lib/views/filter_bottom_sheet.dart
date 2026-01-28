import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../theme/app_theme.dart';
import '../utils/haptic_helper.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Explicitly NO 'late' variables
  bool _tempVegOnly = false;
  bool _tempNonVegOnly = false;
  bool _tempBestsellerOnly = false;
  app_controller.SortOrder _tempSortOrder = app_controller.SortOrder.none;
  List<String> _tempSelectedCategories = [];
  bool _syncInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_syncInitialized) {
      final menuController = Provider.of<app_controller.MenuController>(context, listen: false);
      _tempVegOnly = menuController.isVegOnly;
      _tempNonVegOnly = menuController.isNonVegOnly;
      _tempBestsellerOnly = menuController.isBestsellerOnly;
      _tempSortOrder = menuController.sortOrder;
      _tempSelectedCategories = List.from(menuController.selectedCategories);
      _syncInitialized = true;
    }
  }

  int get _activeCount {
    int count = 0;
    if (_tempVegOnly) count++;
    if (_tempNonVegOnly) count++;
    if (_tempBestsellerOnly) count++;
    if (_tempSortOrder != app_controller.SortOrder.none) count++;
    if (_tempSelectedCategories.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes (only for active counts in footer)
    final menuController = context.watch<app_controller.MenuController>();
    
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Height ~56-60px
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters and Sorting',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C1C1E),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Color(0xFF1C1C1E), size: 24),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E5EA), thickness: 1),

            // Scrollable Sections
            Flexible(
              child: SingleChildScrollView(
                // Bottom padding 96px to prevent hiding behind footer
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Sort by'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildChip(
                          'Price – Low to High',
                          _tempSortOrder == app_controller.SortOrder.priceLowToHigh,
                          () => setState(() => _tempSortOrder = app_controller.SortOrder.priceLowToHigh),
                          showClose: _tempSortOrder == app_controller.SortOrder.priceLowToHigh,
                          onClear: () => setState(() => _tempSortOrder = app_controller.SortOrder.none),
                        ),
                        _buildChip(
                          'Price – High to Low',
                          _tempSortOrder == app_controller.SortOrder.priceHighToLow,
                          () => setState(() => _tempSortOrder = app_controller.SortOrder.priceHighToLow),
                          showClose: _tempSortOrder == app_controller.SortOrder.priceHighToLow,
                          onClear: () => setState(() => _tempSortOrder = app_controller.SortOrder.none),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Intersection spacing 16px
                    _buildSectionTitle('Food Type'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildChip(
                          'Veg',
                          _tempVegOnly,
                          () => setState(() {
                            _tempVegOnly = !_tempVegOnly;
                            if (_tempVegOnly) _tempNonVegOnly = false;
                          }),
                          isVeg: true,
                        ),
                        _buildChip(
                          'Non-Veg',
                          _tempNonVegOnly,
                          () => setState(() {
                            _tempNonVegOnly = !_tempNonVegOnly;
                            if (_tempNonVegOnly) _tempVegOnly = false;
                          }),
                          isNonVeg: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Intersection spacing 16px
                    _buildSectionTitle('Top Picks'),
                    const SizedBox(height: 8),
                    _buildChip(
                      'Bestseller',
                      _tempBestsellerOnly,
                      () => setState(() => _tempBestsellerOnly = !_tempBestsellerOnly),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('Categories'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: menuController.availableCategories.map((category) {
                        final isSelected = _tempSelectedCategories.contains(category);
                        return _buildChip(
                          category,
                          isSelected,
                          () => setState(() {
                            if (isSelected) {
                              _tempSelectedCategories.remove(category);
                            } else {
                              _tempSelectedCategories.add(category);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFE5E5EA), width: 1)),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticHelper.light();
                        setState(() {
                          _tempVegOnly = false;
                          _tempNonVegOnly = false;
                          _tempBestsellerOnly = false;
                          _tempSortOrder = app_controller.SortOrder.none;
                          _tempSelectedCategories = [];
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE5E5EA)),
                      ),
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF8E8E93),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticHelper.medium();
                        menuController.applyFilters(
                          isVegOnly: _tempVegOnly,
                          isNonVegOnly: _tempNonVegOnly,
                          isBestsellerOnly: _tempBestsellerOnly,
                          sortOrder: _tempSortOrder,
                          selectedCategories: _tempSelectedCategories,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6D3F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply${_activeCount > 0 ? ' ($_activeCount)' : ''}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1C1C1E),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, {bool isVeg = false, bool isNonVeg = false, bool showClose = false, VoidCallback? onClear}) {
    return InkWell(
      onTap: () {
        HapticHelper.light();
        if (!showClose) onTap();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F4EC) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F6D3F) : const Color(0xFFE5E5EA),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isVeg || isNonVeg) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isVeg ? const Color(0xFF0F6D3F) : Colors.red,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? const Color(0xFF0F6D3F) : const Color(0xFF1C1C1E),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (showClose && onClear != null) ...[
              const SizedBox(width: 8), // Gap spacing from text: 8px
              InkWell(
                onTap: () {
                  onClear();
                },
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Color(0xFF0F6D3F),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
