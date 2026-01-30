import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/admin_theme.dart';
import 'package:scan_serve/utils/screen_scale.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  final String tenantId;
  
  const SubscriptionPlansScreen({super.key, required this.tenantId});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  final String _currentPlan = 'demo'; // This would come from backend

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'demo',
      'label': 'DEMO',
      'name': 'Demo Plan',
      'price': 0,
      'isFree': true,
      'period': 'Free Forever',
      'pricePerMonth': null,
      'savings': null,
      'badge': 'Current Plan',
      'badgeColor': AdminTheme.success,
      'subtitle': 'For evaluation & testing',
      'features': [
        '5 Tables Limit',
        'Basic Menu Mgmt',
        'Order Tracking',
        'Email Support',
      ],
      'isActive': true,
      'isPurchasable': false,
    },
    {
      'id': '1month',
      'label': 'MONTHLY',
      'name': '1 Month Plan',
      'price': 1799,
      'isFree': false,
      'period': 'month',
      'pricePerMonth': 1799,
      'savings': null,
      'badge': null,
      'badgeColor': null,
      'subtitle': 'Perfect for growing restaurants',
      'features': [
        'Unlimited Tables',
        'Unlimited Orders',
        'KOT Printing',
        'Admin Dashboard',
        'Priority Support',
      ],
      'isActive': false,
      'isPurchasable': true,
    },
    {
      'id': '6month',
      'label': 'RECOMMENDED',
      'name': '6 Month Plan',
      'price': 8999,
      'isFree': false,
      'period': '6 months',
      'pricePerMonth': 1499,
      'savings': 1800,
      'badge': 'Recommended',
      'badgeColor': AdminTheme.warning,
      'subtitle': 'Best for established restaurants',
      'features': [
        'Everything in 1 Month',
        'Inventory Mgmt',
        'Staff Management',
        'Custom Branding',
        '24/7 Priority Support',
      ],
      'isActive': false,
      'isPurchasable': true,
    },
    {
      'id': '12month',
      'label': 'BEST VALUE',
      'name': '12 Month Plan',
      'price': 16999,
      'isFree': false,
      'period': '12 months',
      'pricePerMonth': 1416,
      'savings': 4588,
      'badge': 'Best Value',
      'badgeColor': AdminTheme.primaryColor,
      'subtitle': 'Maximum savings for businesses',
      'features': [
        'Everything in 6 Month',
        'Dedicated Manager',
        'Custom Integrations',
        'White-label options',
        'Onboarding Training',
      ],
      'isActive': false,
      'isPurchasable': true,
    },
  ];

  void _handlePlanPurchase(Map<String, dynamic> plan) {
    if (!plan['isPurchasable'] && plan['id'] != _currentPlan) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Ionicons.information_circle_outline, color: AdminTheme.info, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Coming Soon',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          'Online payments coming soon. Please contact support to activate this plan.\n\nEmail: snick0128@gmail.com\nPhone: +91 6375477065',
          style: GoogleFonts.outfit(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.outfit(
                color: AdminTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1200;
    
    int crossAxisCount;
    double childAspectRatio;
    
    if (isMobile) {
      crossAxisCount = 1;
      childAspectRatio = 0.85;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 0.75;
    } else {
      crossAxisCount = 4; // Desktop: 4 cards in a single row
      childAspectRatio = 0.58;
    }
    
    return Scaffold(
      backgroundColor: AdminTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AdminTheme.topBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back, color: AdminTheme.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 20.w : 40.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Left-aligned header
          children: [
            // Page Header
            Text(
              'Subscription Plans',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 32.sp : 40.sp,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryText,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Manage your subscription and upgrade anytime',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 15.sp : 18.sp,
                color: AdminTheme.secondaryText,
              ),
            ),
            SizedBox(height: 40.h),
            
            // Plans Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20.w,
                mainAxisSpacing: 20.h,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: _plans.length,
              itemBuilder: (context, index) => _buildPlanCard(_plans[index]),
            ),
            
            SizedBox(height: 60.h),
            
            // Contact & Support Section (Bottom)
            Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: 600.w),
                padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 32.w),
                decoration: BoxDecoration(
                  color: AdminTheme.secondaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Need help choosing a plan?',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.primaryText,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 24.w,
                      runSpacing: 12.h,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildContactInfo(Ionicons.mail_outline, 'snick0128@gmail.com'),
                        _buildContactInfo(Ionicons.call_outline, '+91 6375477065'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: AdminTheme.secondaryText),
        SizedBox(width: 8.w),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            color: AdminTheme.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isCurrentPlan = plan['id'] == _currentPlan;
    final isPurchasable = plan['isPurchasable'] as bool;
    final isRecommended = plan['id'] == '6month';
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isRecommended 
              ? AdminTheme.warning 
              : isCurrentPlan 
                  ? AdminTheme.success 
                  : AdminTheme.dividerColor,
          width: isRecommended || isCurrentPlan ? 2 : 1,
        ),
        boxShadow: isRecommended ? [
          BoxShadow(
            color: AdminTheme.warning.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Plan Label (Small, Uppercase)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan['label'],
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: isRecommended ? AdminTheme.warning : AdminTheme.secondaryText,
                ),
              ),
              if (plan['badge'] != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: plan['badgeColor'] ?? AdminTheme.dividerColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    plan['badge'],
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          
          // B. Plan Name
          Text(
            plan['name'],
            style: GoogleFonts.outfit(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AdminTheme.primaryText,
            ),
          ),
          SizedBox(height: 20.h),
          
          // C. Price Block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${plan['price']}',
                    style: GoogleFonts.outfit(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.primaryText,
                      height: 1,
                    ),
                  ),
                  if (plan['id'] == '1month') ...[
                    SizedBox(width: 4.w),
                    Text(
                      '/month',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        color: AdminTheme.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
              if (plan['pricePerMonth'] != null && plan['id'] != '1month') ...[
                SizedBox(height: 4.h),
                Text(
                  '₹${plan['pricePerMonth']} / month',
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    color: AdminTheme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (plan['id'] == 'demo') ...[
                SizedBox(height: 4.h),
                Text(
                  'Free Forever',
                  style: GoogleFonts.outfit(
                    fontSize: 15.sp,
                    color: AdminTheme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          
          // D. Savings Badge (Price anchor helper)
          if (plan['savings'] != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AdminTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Save ₹${plan['savings']}',
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.success,
                ),
              ),
            ),
          ] else SizedBox(height: 38.h), // Equal spacing placeholder
          
          SizedBox(height: 24.h),
          Divider(color: AdminTheme.dividerColor),
          SizedBox(height: 24.h),
          
          // E. Feature List
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (plan['features'] as List).map((feature) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Icon(Ionicons.checkmark_circle, size: 18.sp, color: AdminTheme.success),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          color: AdminTheme.primaryText,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          
          // F. CTA Button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: (isPurchasable || isCurrentPlan) ? () => _handlePlanPurchase(plan) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentPlan 
                    ? AdminTheme.success.withOpacity(0.1) 
                    : isRecommended 
                        ? AdminTheme.warning 
                        : AdminTheme.primaryColor,
                foregroundColor: isCurrentPlan 
                    ? AdminTheme.success 
                    : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                disabledBackgroundColor: AdminTheme.dividerColor,
              ),
              child: Text(
                isCurrentPlan ? 'Current Plan' : 'Coming Soon',
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
