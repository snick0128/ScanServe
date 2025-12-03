import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 60 : 250,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo and App Name
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  const Text(
                    'ScanServe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  )
                else
                  const Text(
                    'SS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isCollapsed
                        ? Icons.chevron_right
                        : Icons.chevron_left,
                    color: Colors.grey,
                  ),
                  onPressed: onToggleCollapse,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.restaurant_menu_outlined,
                  label: 'Menu Items',
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  icon: Icons.table_restaurant_outlined,
                  label: 'Tables',
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Icons.receipt_long_outlined,
                  label: 'Orders',
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  icon: Icons.receipt_outlined,
                  label: 'Bills',
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context: context,
                  index: 5,
                  icon: Icons.analytics_outlined,
                  label: 'Analytics',
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context: context,
                  index: 6,
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  isCollapsed: isCollapsed,
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'SETTINGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _buildNavItem(
                  context: context,
                  index: 7,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context: context,
                  index: 8,
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  isCollapsed: isCollapsed,
                ),
              ],
            ),
          ),
          
          // User profile at bottom
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: ListTile(
              dense: true,
              leading: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
              title: !isCollapsed
                  ? const Text(
                      'Admin User',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              subtitle: !isCollapsed
                  ? const Text(
                      'admin@scanserve.com',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              minLeadingWidth: 8,
              onTap: () {
                // Navigate to profile
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isCollapsed,
  }) {
    final isSelected = selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? colorScheme.primary : Colors.grey[700],
          size: 20,
        ),
        title: !isCollapsed
            ? Text(
                label,
                style: TextStyle(
                  color: isSelected ? colorScheme.primary : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              )
            : null,
        minLeadingWidth: 8,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 8 : 16,
          vertical: 4,
        ),
        dense: true,
        onTap: () => onItemSelected(index),
      ),
    );
  }
}
