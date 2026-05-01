import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/permission_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/yesterday_damage_screen.dart';
import 'providers/theme_provider.dart';
import 'data/services/notification_service.dart';
import 'data/services/usage_stats_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Global navigator key so notifications can push routes from outside the widget tree
final _navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: _navigatorKey,
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
    // Register the morning roast notification tap handler
    NotificationService.onDailyRoastTapped = () {
      _navigatorKey.currentState?.push(
        PageRouteBuilder(
          pageBuilder:        (_, __, ___) => const YesterdayDamageScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    };
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
      setState(() {
        _home = const OnboardingScreen();
      });
      FlutterNativeSplash.remove();
      return;
    }

    bool hasPermission = false;
    if (Platform.isAndroid) {
      hasPermission = await UsageStatsService().checkPermission();
    }

    if (!mounted) return;

    setState(() {
      _home = hasPermission ? const HomeScreen() : const PermissionScreen();
    });
    
    // Remove the native splash screen ONLY after we know exactly what screen to show
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    if (_home == null) {
      return const SizedBox.shrink();
    }
    return _home!;
  }
}
