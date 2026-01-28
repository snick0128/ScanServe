import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';
import '../theme/admin_theme.dart';
import 'package:scan_serve/utils/screen_scale.dart';

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
      width: isCollapsed ? 72.w : 260.w,
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
            height: 80.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Ionicons.restaurant, 
                    color: AdminTheme.primaryColor, size: 24.w),
                ),
                if (!isCollapsed) ...[
                  SizedBox(width: 12.w),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan & Serve',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.primaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'ADMIN PORTAL',
                        style: TextStyle(
                          fontSize: 11.sp,
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
              padding: EdgeInsets.symmetric(horizontal: 12.w),
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
                  if (role != 'captain')
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
                  if (role != 'captain')
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
            horizontal: isCollapsed ? 0 : 16.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AdminTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AdminTheme.primaryColor : AdminTheme.secondaryText,
                size: 22.w,
              ),
              if (!isCollapsed) ...[
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AdminTheme.primaryText : AdminTheme.secondaryText,
                      fontSize: 15.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AdminTheme.primaryColor.withOpacity(0.2),
            backgroundImage: const NetworkImage('https://i.pravatar.cc/150?u=manager'),
          ),
          if (!isCollapsed) ...[
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'James Wilson',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    role?.toUpperCase() ?? 'MANAGER',
                    style: TextStyle(
                      fontSize: 10.sp,
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
              icon: Icon(Ionicons.log_out_outline, 
                color: AdminTheme.critical, size: 20.w),
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

