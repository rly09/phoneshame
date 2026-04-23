import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/permission_screen.dart';
import 'providers/theme_provider.dart';

class ROTApp extends ConsumerWidget {
  const ROTApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Update status bar icons based on theme mode
    SystemChrome.setSystemUIOverlayStyle(
      themeMode == ThemeMode.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );

    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const _RootRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Decides whether to show onboarding or go straight to permission check.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final done = await OnboardingScreen.isCompleted();
    if (!mounted) return;
    setState(() {
      _home = done ? const PermissionScreen() : const OnboardingScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_home == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const SizedBox.shrink(),
      );
    }
    return _home!;
  }
}
