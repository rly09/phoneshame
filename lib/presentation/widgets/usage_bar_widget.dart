import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/app_usage_model.dart';
import '../../core/utils/time_formatter.dart';
import 'app_icon_widget.dart';

class UsageBarWidget extends StatefulWidget {
  final List<AppUsageModel> apps;
  const UsageBarWidget({super.key, required this.apps});

  @override
  State<UsageBarWidget> createState() => _UsageBarWidgetState();
}

class _UsageBarWidgetState extends State<UsageBarWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>>   _slideAnims;

  @override
  void initState() {
    super.initState();
    _buildAnimations(widget.apps.length);
  }

  @override
  void didUpdateWidget(UsageBarWidget old) {
    super.didUpdateWidget(old);
    if (old.apps != widget.apps) {
      for (final c in _controllers) { c.dispose(); }
      _buildAnimations(widget.apps.length);
    }
  }

  void _buildAnimations(int count) {
    _controllers = List.generate(count, (i) => AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 300),
    ));
    _slideAnims = _controllers.map((c) => Tween<Offset>(
      begin: const Offset(0, 0.4),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();

    // Staggered start: 60ms between each, cap at 15 so long lists don't take forever
    for (int i = 0; i < _controllers.length; i++) {
      final delay = i < 15 ? i * 60 : 900;
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  Color _barColor(BuildContext context, int minutes) {
    // Per-app usage bar color
    if (minutes < 30)  return context.colors.green;
    if (minutes < 120) return context.colors.amber;
    return context.colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.apps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              const Text('😅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'open some apps first',
                style: GoogleFonts.poppins(
                  color:    context.colors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final topApps = widget.apps;
    final maxMins = topApps.first.totalTimeInMinutes > 0
        ? topApps.first.totalTimeInMinutes
        : 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHERE YOUR TIME WENT',
          style: GoogleFonts.poppins(
            fontSize:      11,
            fontWeight:    FontWeight.w600,
            letterSpacing: 1.5,
            color:         context.colors.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color:        context.colors.surface,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: context.colors.border),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: AppColors.cDarkest.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 365),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: List.generate(topApps.length, (i) {
              final app      = topApps[i];
              final fraction = app.totalTimeInMinutes / maxMins;
              final color    = _barColor(context, app.totalTimeInMinutes);

              final row = FadeTransition(
                opacity: i < _controllers.length
                    ? _controllers[i]
                    : const AlwaysStoppedAnimation(1.0),
                child: SlideTransition(
                  position: i < _slideAnims.length
                      ? _slideAnims[i]
                      : const AlwaysStoppedAnimation(Offset.zero),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Real app icon
                        AppIconWidget(
                          packageName:   app.packageName,
                          appName:       app.appName,
                          size:          40,
                          fallbackColor: color,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      app.appName,
                                      maxLines:     1,
                                      overflow:     TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        color:      context.colors.textPrimary,
                                        fontSize:   15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    TimeFormatter.formatMinutesToHours(
                                        app.totalTimeInMinutes),
                                    style: GoogleFonts.poppins(
                                      color:      context.colors.textSecondary,
                                      fontSize:   13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value:            fraction.clamp(0.0, 1.0),
                                  backgroundColor:  context.colors.border,
                                  valueColor:       AlwaysStoppedAnimation(color),
                                  minHeight:        4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (i < topApps.length - 1) {
                return Column(children: [
                  row,
                  Divider(height: 1, indent: 70, endIndent: 16, color: context.colors.border),
                ]);
              }
              return row;
            }),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
