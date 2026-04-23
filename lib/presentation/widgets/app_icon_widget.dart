import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/app_icon_service.dart';

/// Shows the real app icon fetched from Android PackageManager.
/// Falls back to a colored initial circle if the icon can't be loaded.
class AppIconWidget extends StatefulWidget {
  final String  packageName;
  final String  appName;
  final double  size;
  final Color?  fallbackColor;

  const AppIconWidget({
    super.key,
    required this.packageName,
    required this.appName,
    this.size = 40,
    this.fallbackColor,
  });

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  Uint8List? _bytes;
  bool       _loaded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(AppIconWidget old) {
    super.didUpdateWidget(old);
    if (old.packageName != widget.packageName) _fetch();
  }

  Future<void> _fetch() async {
    final bytes = await AppIconService.instance.getIcon(widget.packageName);
    if (mounted) setState(() { _bytes = bytes; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;

    if (_loaded && _bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(s * 0.25),
        child: Image.memory(
          _bytes!,
          width:  s,
          height: s,
          fit:    BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    final fColor = widget.fallbackColor ?? context.colors.purple;

    // Fallback: initial letter circle
    final initial = widget.appName.isNotEmpty
        ? widget.appName[0].toUpperCase()
        : '?';
    return Container(
      width:  s,
      height: s,
      decoration: BoxDecoration(
        color:        fColor.withAlpha(30),
        borderRadius: BorderRadius.circular(s * 0.25),
        border:       Border.all(color: fColor.withAlpha(60)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color:      fColor,
          fontSize:   s * 0.45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
