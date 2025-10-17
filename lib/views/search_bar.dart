import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/menu_controller.dart' as app_controller;

class SearchBar extends StatefulWidget {
  final double maxWidth;

  const SearchBar({Key? key, required this.maxWidth}) : super(key: key);

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar>
    with TickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _elevationAnimation = Tween<double>(
      begin: 0,
      end: 4,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        return Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: _elevationAnimation.value,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FocusScope(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  _focusController.forward();
                } else {
                  _focusController.reverse();
                }
              },
              child: TextField(
                onChanged: (value) {
                  context.read<app_controller.MenuController>().setSearchQuery(value);
                },
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search menu items...',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: isMobile ? 14 : 16,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                      size: isMobile ? 20 : 22,
                    ),
                  ),
                  suffixIcon: Consumer<app_controller.MenuController>(
                    builder: (context, controller, child) {
                      if (controller.searchQuery.isNotEmpty) {
                        return IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[600],
                            size: isMobile ? 20 : 22,
                          ),
                          onPressed: () {
                            controller.setSearchQuery('');
                          },
                          padding: const EdgeInsets.all(12),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF6E40),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 20,
                    vertical: isMobile ? 12 : 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
