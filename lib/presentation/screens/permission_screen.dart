import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/usage_stats_service.dart';
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  final _service   = UsageStatsService();
  bool  _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final ok = await _service.checkPermission();
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:        (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  Future<void> _requestAccess() async {
    setState(() => _isLoading = true);
    await _service.requestUsageAccess();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return Scaffold(
        backgroundColor: context.colors.bg,
        body: Center(
          child: Text(
            'ROT is Android only right now.',
            style: GoogleFonts.poppins(color: context.colors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width:  88,
                height: 88,
                decoration: BoxDecoration(
                  color:  context.colors.surface,
                  shape:  BoxShape.circle,
                  border: Border.all(color: context.colors.border, width: 1.5),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: AppColors.cDarkest.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Center(
                  child: Text('📱', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 36),

              Text(
                'we need to see\nhow much you\nwasted today.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color:         context.colors.textPrimary,
                  fontSize:      28,
                  fontWeight:    FontWeight.w800,
                  height:        1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'ROT needs Usage Access to read your daily screen time. Enable it so we can judge you properly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color:    context.colors.textSecondary,
                  fontSize: 15,
                  height:   1.6,
                ),
              ),
              const SizedBox(height: 48),

              // CTA
              SizedBox(
                width:  double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestAccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.cLightest, strokeWidth: 2)
                      : Text(
                          'give access',
                          style: GoogleFonts.poppins(
                            color:      AppColors.cLightest,
                            fontSize:   16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'your data never leaves your device.',
                style: GoogleFonts.poppins(
                  color:   context.colors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
