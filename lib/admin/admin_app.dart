import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/auth/login_screen.dart';
import 'providers/orders_provider.dart';
import 'providers/admin_auth_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/tables_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/bills_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/background_print_provider.dart';
import 'theme/admin_theme.dart';
import '../theme/app_theme.dart';
import 'package:scan_serve/utils/screen_scale.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminAuthProvider>(
          create: (_) => AdminAuthProvider(),
        ),
        ChangeNotifierProvider<ActivityProvider>(
          create: (_) => ActivityProvider(),
        ),
        ChangeNotifierProxyProvider2<AdminAuthProvider, ActivityProvider, OrdersProvider>(
          create: (_) => OrdersProvider(),
          update: (_, auth, activity, orders) {
            if (auth.tenantId != null && orders != null) {
              orders.initialize(auth.tenantId!, auth: auth, activity: activity);
              activity.initialize(auth.tenantId!);
            }
            return orders ?? OrdersProvider();
          },
        ),
        ChangeNotifierProxyProvider2<AdminAuthProvider, OrdersProvider, TablesProvider>(
          create: (_) => TablesProvider(),
          update: (_, auth, orders, tables) {
            if (auth.tenantId != null && tables != null) {
              tables.initialize(auth.tenantId!, ordersProvider: orders);
            }
            return tables ?? TablesProvider();
          },
        ),
        ChangeNotifierProxyProvider<AdminAuthProvider, NotificationsProvider>(
          create: (_) => NotificationsProvider(),
          update: (_, auth, notifications) {
            if (auth.tenantId != null && notifications != null) {
              notifications.initialize(auth.tenantId!);
            }
            return notifications ?? NotificationsProvider();
          },
        ),
        ChangeNotifierProxyProvider<AdminAuthProvider, InventoryProvider>(
          create: (_) => InventoryProvider(''),
          update: (_, auth, previous) {
            // Only recreate if tenantId actually changed and is valid
            if (auth.tenantId != null && auth.tenantId!.isNotEmpty && previous?.tenantId != auth.tenantId) {
              return InventoryProvider(auth.tenantId!);
            }
            return previous ?? InventoryProvider('');
          },
        ),
        ChangeNotifierProxyProvider2<AdminAuthProvider, OrdersProvider, BillsProvider>(
          create: (_) => BillsProvider(),
          update: (_, auth, orders, bills) {
            if (auth.tenantId != null && bills != null) {
              bills.initialize(auth.tenantId!, ordersProvider: orders);
            }
            return bills ?? BillsProvider();
          },
        ),
        ChangeNotifierProxyProvider<AdminAuthProvider, MenuProvider>(
          create: (_) => MenuProvider(),
          update: (_, auth, menu) {
            if (auth.tenantId != null && menu != null) {
              menu.initialize(auth.tenantId!);
            }
            return menu ?? MenuProvider();
          },
        ),
        ChangeNotifierProxyProvider<AdminAuthProvider, AnalyticsProvider>(
          create: (_) => AnalyticsProvider(),
          update: (_, auth, analytics) {
            if (auth.tenantId != null && analytics != null) {
              analytics.initialize(auth.tenantId!);
            }
            return analytics ?? AnalyticsProvider();
          },
        ),
        ChangeNotifierProxyProvider<AdminAuthProvider, BackgroundPrintProvider>(
          create: (_) => BackgroundPrintProvider(),
          update: (_, auth, printing) {
            if (auth.tenantId != null && printing != null) {
              printing.initialize(auth.tenantId!);
            }
            return printing ?? BackgroundPrintProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'ScanServe Admin',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.lightTheme,
        builder: (context, child) {
          ScreenScale.init(context);
          return child!;
        },
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const AdminLoginScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.canAccessAdminPanel) {
          return DashboardScreen(tenantId: auth.tenantId ?? 'global');
        }

        return const AdminLoginScreen();
      },
    );
  }
}
