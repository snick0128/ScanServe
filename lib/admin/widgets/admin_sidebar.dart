import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final String? role;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.role,
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
                        ? Ionicons.chevron_forward_outline
                        : Ionicons.chevron_back_outline,
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
                if (role == 'superadmin' && context.read<AdminAuthProvider>().tenantId != 'global') ...[
                  _buildNavItem(
                    context: context,
                    index: 10,
                    icon: Ionicons.planet_outline,
                    label: 'Master Console',
                    isCollapsed: isCollapsed,
                    onTapOverride: () {
                      context.read<AdminAuthProvider>().resetToGlobal();
                      onItemSelected(10);
                    },
                    colorOverride: Colors.purple,
                  ),
                  const Divider(height: 16),
                ],
                if (role != 'kitchen' && role != 'captain') ...[
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Ionicons.grid_outline,
                    label: 'Dashboard',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Ionicons.restaurant_outline,
                    label: 'Menu Items',
                    isCollapsed: isCollapsed,
                  ),
                ],
                if (role != 'kitchen') ...[
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: Ionicons.apps_outline,
                    label: 'Tables',
                    isCollapsed: isCollapsed,
                  ),
                ],
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Ionicons.list_outline,
                  label: 'Orders',
                  isCollapsed: isCollapsed,
                ),
                if (role != 'kitchen' && role != 'captain') ...[
                  _buildNavItem(
                    context: context,
                    index: 4,
                    icon: Ionicons.receipt_outline,
                    label: 'Bills',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 5,
                    icon: Ionicons.stats_chart_outline,
                    label: 'Analytics',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 6,
                    icon: Ionicons.cube_outline,
                    label: 'Inventory',
                    isCollapsed: isCollapsed,
                  ),
                ],
                const SizedBox(height: 8),
                if (role != 'kitchen' && role != 'captain') ...[
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
                    icon: Ionicons.settings_outline,
                    label: 'Settings',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 9,
                    icon: Ionicons.list_outline,
                    label: 'Activity Logs',
                    isCollapsed: isCollapsed,
                  ),
                ],
                  _buildNavItem(
                    context: context,
                    index: 8,
                    icon: Ionicons.help_circle_outline,
                    label: 'Help & Support',
                    isCollapsed: isCollapsed,
                  ),
                if (role == 'superadmin') ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'SUPER ADMIN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 10,
                    icon: Ionicons.business_outline,
                    label: 'Manage Tenants',
                    isCollapsed: isCollapsed,
                  ),
                ],
              ],
            ),
          ),
          
          // User profile at bottom
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue,
                    child: Icon(Ionicons.person, size: 12, color: Colors.white),
                  ),
                  title: !isCollapsed
                      ? Text(
                          role == 'superadmin' ? 'Super Admin' :
                          role == 'kitchen' ? 'Kitchen Staff' : 
                          role == 'captain' ? 'Captain/Waiter' : 'Admin User',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  minLeadingWidth: 8,
                ),
                ListTile(
                  dense: true,
                  leading: Icon(
                    Ionicons.log_out_outline,
                    size: 20,
                    color: Colors.red[400],
                  ),
                  title: !isCollapsed
                      ? Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red[400],
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  minLeadingWidth: 8,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<AdminAuthProvider>().signOut();
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
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
    VoidCallback? onTapOverride,
    Color? colorOverride,
  }) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = colorOverride ?? colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? activeColor : Colors.grey[700],
          size: 20,
        ),
        title: !isCollapsed
            ? Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : Colors.grey[800],
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
        onTap: onTapOverride ?? () => onItemSelected(index),
      ),
    );
  }
}
