import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/auth/login_screen.dart';
import 'providers/orders_provider.dart';
import 'providers/admin_auth_provider.dart';
import '../theme/app_theme.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminAuthProvider>(
          create: (_) => AdminAuthProvider(),
        ),
        ChangeNotifierProxyProvider<AdminAuthProvider, OrdersProvider>(
          create: (_) => OrdersProvider(),
          update: (_, auth, orders) {
            if (auth.tenantId != null && orders != null) {
              orders.initialize(auth.tenantId!);
            }
            return orders ?? OrdersProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'ScanServe Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const AdminLoginScreen(),
          '/dashboard': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
            final tenantId = args?['tenantId'] ?? 'demo_tenant';
            return DashboardScreen(tenantId: tenantId);
          },
          '/orders': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
            final tenantId = args?['tenantId'] ?? 'demo_tenant';
            return OrdersScreen(tenantId: tenantId);
          },
        },
      ),
    );
  }
}
