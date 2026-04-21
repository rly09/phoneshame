import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'presentation/screens/permission_screen.dart';

class PhoneShameApp extends StatelessWidget {
  const PhoneShameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const PermissionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
