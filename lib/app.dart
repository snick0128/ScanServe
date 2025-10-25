import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scan_serve/controllers/cart_controller.dart';
import 'package:scan_serve/controllers/menu_controller.dart' as app_controller;
import 'package:scan_serve/controllers/order_controller.dart';
import 'package:scan_serve/utils/qr_url_parser.dart';
import 'package:scan_serve/views/home_page.dart';
import 'controllers/auth_controller.dart';
import 'services/guest_session_service.dart';
import 'services/offline_service.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

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
        home: const Initializer(),
      ),
    );
  }
}

class Initializer extends StatefulWidget {
  const Initializer({Key? key}) : super(key: key);

  @override
  State<Initializer> createState() => _InitializerState();
}

class _InitializerState extends State<Initializer> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    print('Starting app initialization');

    // Get the actual URL from the window location in web
    String url = Uri.base.toString();
    print('Current URL: $url');

    // For development/testing, use a default tenant if no URL parameters
    if (!url.contains('tenantId')) {
      print('No tenantId in URL, using demo_tenant');
      url =
          '$url${url.contains('?') ? '&' : '?'}tenantId=demo_tenant&tableId=table_1';
    }

    final params = QrUrlParser.parseUrl(url);
    print('Parsed URL parameters: $params');

    final guestSession = GuestSessionService();
    await guestSession.getOrCreateGuestId();
    await guestSession.startSession(
      tenantId: params['tenantId'] ?? 'demo_tenant',
    );

    final tenantId = params['tenantId'];
    final tableId = params['tableId'];

    if (tenantId != null) {
      final orderController = context.read<OrderController>();
      orderController.setSession(tenantId, tableId);

      // Load menu items for the tenant
      final menuController = context.read<app_controller.MenuController>();
      await menuController.loadMenuItems(tenantId);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(tenantId: tenantId)),
      );
    } else {
      // Handle invalid QR code
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid QR Code')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
