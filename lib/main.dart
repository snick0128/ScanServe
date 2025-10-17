import 'package:flutter/material.dart';
import 'package:scan_serve/app.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const App());
}
