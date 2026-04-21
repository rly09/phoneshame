import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/usage_stats_service.dart';
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  final _service = UsageStatsService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
       _checkPermission();
    }
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
    final hasPermission = await _service.checkPermission();
    if (hasPermission) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
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
      return const Scaffold(
        body: Center(
          child: Text(
            "PhoneShame is only supported on Android right now.",
            style: TextStyle(fontSize: 18, color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.privacy_tip_rounded,
                size: 80,
                color: AppColors.accent,
              ),
              const SizedBox(height: 32),
              const Text(
                "We need to see how much time you waste.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "PhoneShame requires Usage Access to read your daily screen time. Enable it in Settings to let us judge you.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestAccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Give Access",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Don't worry, we never upload your data. It stays on your device.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
    );
  }
}
