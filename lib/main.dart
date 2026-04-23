import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // ignore if not found
  }

  runApp(
    const ProviderScope(
      child: ROTApp(),
    ),
  );
}
