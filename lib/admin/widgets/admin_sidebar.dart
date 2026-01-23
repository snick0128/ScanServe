import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 72 : 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AdminTheme.sidebarBackground,
        border: Border(
          right: BorderSide(color: AdminTheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo Section
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Ionicons.restaurant, 
                    color: AdminTheme.primaryColor, size: 24),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan & Serve',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.primaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'ADMIN PORTAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.secondaryText,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Navigation Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (role != 'kitchen') ...[
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Ionicons.grid_outline,
                    activeIcon: Ionicons.grid,
                    label: 'Dashboard',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: Ionicons.list_outline,
                    activeIcon: Ionicons.list,
                    label: 'Orders',
                    isCollapsed: isCollapsed,
                  ),
                ],
                _buildNavItem(
                  context: context,
                  index: 9,
                  icon: Ionicons.desktop_outline,
                  activeIcon: Ionicons.desktop,
                  label: 'KDS',
                  isCollapsed: isCollapsed,
                ),
                if (role != 'kitchen') ...[
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Ionicons.restaurant_outline,
                    activeIcon: Ionicons.restaurant,
                    label: 'Menu',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: Ionicons.tablet_landscape_outline,
                    activeIcon: Ionicons.tablet_landscape,
                    label: 'Tables',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 8,
                    icon: Ionicons.cube_outline,
                    activeIcon: Ionicons.cube,
                    label: 'Inventory',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 4,
                    icon: Ionicons.receipt_outline,
                    activeIcon: Ionicons.receipt,
                    label: 'Billing',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 6,
                    icon: Ionicons.people_outline,
                    activeIcon: Ionicons.people,
                    label: 'Staff',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 5,
                    icon: Ionicons.stats_chart_outline,
                    activeIcon: Ionicons.stats_chart,
                    label: 'Reports',
                    isCollapsed: isCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 7,
                    icon: Ionicons.settings_outline,
                    activeIcon: Ionicons.settings,
                    label: 'Settings',
                    isCollapsed: isCollapsed,
                  ),
                ],
              ],
            ),
          ),

          // Bottom Section
          _buildUserProfile(context),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isCollapsed,
  }) {
    final isSelected = selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onItemSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AdminTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AdminTheme.primaryColor : AdminTheme.secondaryText,
                size: 22,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AdminTheme.primaryText : AdminTheme.secondaryText,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    final auth = context.read<AdminAuthProvider>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AdminTheme.primaryColor.withOpacity(0.2),
            backgroundImage: const NetworkImage('https://i.pravatar.cc/150?u=manager'),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'James Wilson',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role?.toUpperCase() ?? 'MANAGER',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AdminTheme.secondaryText,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Ionicons.log_out_outline, 
                color: AdminTheme.critical, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.cardBackground,
        title: const Text('Confirm Logout'),
        content: const Text('Do you want to sign out from the portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AdminAuthProvider>().signOut();
            },
            child: const Text('LOGOUT', style: TextStyle(color: AdminTheme.critical)),
          ),
        ],
      ),
    );
  }
}

