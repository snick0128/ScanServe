import 'package:flutter/material.dart';
import 'package:scan_serve/app.dart';
import 'package:scan_serve/config/app_config.dart';
import 'services/firebase_service.dart';

import 'package:flutter/foundation.dart';
import 'package:scan_serve/admin/admin_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  
  if (kIsWeb && Uri.base.path.startsWith('/admin')) {
    runApp(const AdminApp());
    return;
  }
  
  // Initialize configuration from URL parameters
  final appConfig = AppConfig.init();
  
  runApp(App(config: appConfig));
}
