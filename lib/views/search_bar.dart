import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/menu_controller.dart' as app_controller;
import '../theme/app_theme.dart';
import '../utils/haptic_helper.dart';
import 'package:scan_serve/utils/screen_scale.dart';

class SearchBar extends StatefulWidget {
  final double maxWidth;

  const SearchBar({Key? key, required this.maxWidth}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48, // Updated to match Waiter button
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2.r), // Highly visible border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4), 
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          context.read<app_controller.MenuController>().setSearchQuery(value);
        },
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: AppTheme.primaryText,
          height: 1.2, // IMPORTANT for vertical centering
        ),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true, // 🔥 fixes height math
          hintText: 'Search menu items...',
          hintStyle: GoogleFonts.outfit(
            color: const Color(0xFF8E8E93),
            fontSize: 14,
            height: 1.2,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search,
              color: Color(0xFF8E8E93),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: Consumer<app_controller.MenuController>(
            builder: (context, controller, child) {
              if (controller.searchQuery.isNotEmpty) {
                return GestureDetector(
                  onTap: () {
                    HapticHelper.light();
                    _controller.clear();
                    controller.setSearchQuery('');
                    FocusScope.of(context).unfocus();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.clear,
                      color: Color(0xFF8E8E93),
                      size: 18,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
