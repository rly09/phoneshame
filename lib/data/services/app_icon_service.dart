import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Singleton that fetches and caches app icon PNG bytes from the
/// Android PackageManager via the existing usage_stats method channel.
class AppIconService {
  AppIconService._();
  static final AppIconService instance = AppIconService._();

  static const _channel = MethodChannel('com.phoneshame/usage_stats');

  final _cache = <String, Uint8List?>{};

  Future<Uint8List?> getIcon(String packageName) async {
    if (_cache.containsKey(packageName)) return _cache[packageName];
    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'getAppIcon',
        {'packageName': packageName},
      );
      final bytes = raw is Uint8List ? raw : (raw as List<dynamic>?)?.let(
        (l) => Uint8List.fromList(l.cast<int>()),
      );
      _cache[packageName] = bytes;
      return bytes;
    } catch (_) {
      _cache[packageName] = null;
      return null;
    }
  }
}

extension _LetExt<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
