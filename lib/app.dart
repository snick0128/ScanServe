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
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
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
    final guestSession = GuestSessionService();
    await guestSession.startSession(tenantId: 'demo_tenant');

    // This is a placeholder for the actual URL from the browser
    const url = 'https://example.com/?tenantId=demo_tenant&tableId=table_1';
    final params = QrUrlParser.parseUrl(url);

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
