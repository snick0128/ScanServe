import 'package:flutter/material.dart';
import 'package:scan_serve/views/checkout_page.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/controllers/cart_controller.dart';
import 'package:scan_serve/controllers/menu_controller.dart' as app_controller;
import 'package:scan_serve/controllers/order_controller.dart';
import 'package:scan_serve/config/app_config.dart';
import 'package:scan_serve/views/home_page.dart';
import 'package:scan_serve/models/order_model.dart';
import 'controllers/auth_controller.dart';
import 'services/guest_session_service.dart';
import 'services/offline_service.dart';
import 'services/tenant_service.dart';

class App extends StatelessWidget {
  final AppConfig config;

  const App({Key? key, required this.config}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => app_controller.MenuController()),
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        Provider<OfflineService>(
          create: (_) => OfflineService()..initialize(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: MaterialApp(
        title: 'ScanServe',
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: Colors.deepPurple,
            primaryContainer: Colors.deepPurple,
            secondary: Colors.deepPurpleAccent,
            secondaryContainer: Colors.deepPurpleAccent,
            tertiary: Colors.indigoAccent,
            surface: Colors.white,
            background: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black87,
            onBackground: Colors.black87,
          ),
          useMaterial3: true,
          // Enhanced Material 3 styling
          appBarTheme: AppBarTheme(
            elevation: 2,
            shadowColor: Colors.deepPurple.withOpacity(0.1),
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            surfaceTintColor: Colors.white,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shadowColor: Colors.deepPurple.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        home: Initializer(config: config),
        onGenerateRoute: (settings) {
          if (settings.name == '/checkout') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => CheckoutPage(
                tenantId: args['tenantId'],
                orderType: args['orderType'],
                tableId: args['tableId'],
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

class Initializer extends StatefulWidget {
  final AppConfig config;

  const Initializer({Key? key, required this.config}) : super(key: key);

  @override
  State<Initializer> createState() => _InitializerState();
}

class _InitializerState extends State<Initializer> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final tenantId = widget.config.tenantId;
    final tableId = widget.config.tableId;
    final orderType = widget.config.orderType ?? 
        (tableId != null && tableId.isNotEmpty ? OrderType.dineIn : OrderType.parcel);

    print('🚀 Starting Init - Tenant: $tenantId, Table: $tableId, Type: $orderType');

    try {
      final tenantService = TenantService();
      final guestSession = GuestSessionService();
      
      // 1. Initialize Session (Guest ID)
      final guestId = await guestSession.getOrCreateGuestId();

      // 2. Validate Tenant
      final tenant = await tenantService.getTenantInfo(tenantId);
      if (tenant == null) {
        _showError('Invalid Store. Please contact staff.');
        return;
      }

      // 3. Strict Logic for Dine-in
      if (orderType == OrderType.dineIn) {
        if (tableId == null || tableId.isEmpty) {
          _showError('Table number is required for Dine-in.');
          return;
        }

        // Validate Table Exists
        final tableExists = await tenantService.verifyTableExists(tenantId, tableId);
        if (!tableExists) {
          _showError('Invalid Table. Please contact staff.');
          return;
        }

        // Lock Table / Check Active Session
        final isLocked = await tenantService.lockTable(tenantId, tableId, guestId);
        if (!isLocked) {
          _showError('This table already has an active order.');
          return;
        }
      }

      // 4. Start Session
      await guestSession.startSession(
        tenantId: tenantId,
        tableId: tableId,
      );

      // 5. Setup Controllers
      if (!mounted) return;
      
      final orderController = context.read<OrderController>();
      await orderController.setOrderType(orderType);
      orderController.setSession(tenantId, tableId);

      // Initialize Cart Persistence
      final cartController = context.read<CartController>();
      await cartController.initialize(tenantId, tableId);

      final menuController = context.read<app_controller.MenuController>();
      await menuController.loadMenuItems(tenantId);
      menuController.startInventoryListener(tenantId);

      // 6. Navigate
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(tenantId: tenantId)),
        );
      }
    } catch (e) {
      print('Initialization Error: $e');
      _showError('Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 24),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please scan a valid QR code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
