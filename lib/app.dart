import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/permission_screen.dart';
import 'providers/theme_provider.dart';
import 'data/services/notification_service.dart';

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

class _RootRouterState extends State<_RootRouter> with WidgetsBindingObserver {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resolve();
    _handleNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleNotifications();
    }
  }

  Future<void> _handleNotifications() async {
    final ns = NotificationService();
    // Cancel the 10PM nudge as the app is opened
    await ns.cancelNudge();
    // Re-schedule all notifications with fresh data
    await ns.scheduleAllNotifications();
  }

  Future<void> _resolve() async {
    final done = await OnboardingScreen.isCompleted();
    if (!mounted) return;
    
    if (!done) {
      // First launch logic (if any other than permissions)
    }

    setState(() {
      _home = done ? const PermissionScreen() : const OnboardingScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_home == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _home!;
  }
}
