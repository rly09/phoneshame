import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/time_formatter.dart';

/// Generates and caches an AI roast + alternatives for yesterday's screen time.
class DailyRoastService {
  static const String _roastTextKey      = 'daily_roast_text';
  static const String _roastDateKey      = 'daily_roast_date';
  static const String _yesterdayMinsKey  = 'daily_roast_total_mins';
  static const String _yesterdayTopKey   = 'daily_roast_top_app';
  static const String _yesterdayScoreKey = 'daily_roast_score';
  static const String _alternativesKey   = 'daily_roast_alternatives';

  Future<void> generateAndCache({
    required int totalMinutes,
    required int score,
    required String topApp,
    required String topAppMinutes,
    required List<String> topApps,
  }) async {
    // Run both API calls in parallel
    final results = await Future.wait([
      _fetchRoast(
        totalMinutes: totalMinutes,
        topApp: topApp,
        topAppMinutes: topAppMinutes,
        topApps: topApps,
      ),
      _fetchAlternatives(
        totalMinutes: totalMinutes,
        topApps: topApps,
      ),
    ]);

    final roastText    = results[0] as String;
    final alternatives = results[1] as List<String>;

    final prefs   = await SharedPreferences.getInstance();
    final today   = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';

    await prefs.setString(_roastTextKey, roastText);
    await prefs.setString(_roastDateKey, dateKey);
    await prefs.setInt(_yesterdayMinsKey, totalMinutes);
    await prefs.setString(_yesterdayTopKey, topApp);
    await prefs.setInt(_yesterdayScoreKey, score);
    await prefs.setStringList(_alternativesKey, alternatives);
  }

  static Future<String?> getCachedRoastText() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roastTextKey);
  }

  static Future<Map<String, dynamic>?> getCachedRoastData() async {
    final prefs = await SharedPreferences.getInstance();
    final text  = prefs.getString(_roastTextKey);
    if (text == null || text.isEmpty) return null;

    return {
      'text':         text,
      'totalMinutes': prefs.getInt(_yesterdayMinsKey) ?? 0,
      'topApp':       prefs.getString(_yesterdayTopKey) ?? '—',
      'score':        prefs.getInt(_yesterdayScoreKey) ?? 0,
      'alternatives': prefs.getStringList(_alternativesKey) ?? <String>[],
    };
  }

  // ── Fetch roast ──────────────────────────────────────────────────────────────

  Future<String> _fetchRoast({
    required int totalMinutes,
    required String topApp,
    required String topAppMinutes,
    required List<String> topApps,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return _fallbackRoast(totalMinutes, topApp);

    final totalStr   = TimeFormatter.formatMinutesToHours(totalMinutes);
    final topAppList = topApps.take(3).join(', ');

    final prompt = '''
Yesterday, this user spent $totalStr on their phone.
Their most-used app was $topApp ($topAppMinutes). Top 3 apps: $topAppList.

Write ONE devastating, brutally funny sentence roasting them for wasting their day.
Be savage, witty, specific. Under 140 characters. No quotes. Just the roast.''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'system', 'content': 'You are a brutally funny savage roaster. Short punchy one-liners. No emojis. No hashtags.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 80,
        }),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['choices'][0]['message']['content'] as String).trim();
      }
    } catch (_) {}
    return _fallbackRoast(totalMinutes, topApp);
  }

  // ── Fetch alternatives ───────────────────────────────────────────────────────

  Future<List<String>> _fetchAlternatives({
    required int totalMinutes,
    required List<String> topApps,
  }) async {
    return AlternativesService.generate(totalMinutes: totalMinutes, topApps: topApps);
  }

  // ── Fallbacks ────────────────────────────────────────────────────────────────

  String _fallbackRoast(int totalMinutes, String topApp) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final t = h > 0 ? '${h}h ${m}m' : '${m}m';
    final list = [
      '$t on $topApp. That\'s not a habit, that\'s a lifestyle your future self will regret.',
      'You spent $t staring at $topApp. Archaeologists will study you as evidence of digital decay.',
      '$t gone. $topApp won. You lost. Again.',
    ];
    return list[DateTime.now().second % list.length];
  }
}

// ────────────────────────────────────────────────────────────────────────────
/// Generates AI-powered "instead you could have" alternatives on demand.
/// Used by both the live Roast Bottom Sheet and the cached Daily Roast.
class AlternativesService {
  static Future<List<String>> generate({
    required int totalMinutes,
    required List<String> topApps,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return _fallback(totalMinutes);

    final totalStr  = TimeFormatter.formatMinutesToHours(totalMinutes);
    final appsStr   = topApps.take(2).join(' and ');

    final prompt = '''
Someone spent $totalStr on their phone, mostly on $appsStr.

Give me exactly 3 specific, meaningful, inspiring things they could have done instead with $totalStr.

Rules:
- Be creative and concrete, not generic ("read a book" is too vague — "read 40 pages of Atomic Habits" is better)
- Calibrate to the time available: $totalStr is the exact time budget
- Think: partial skill learning, local experiences, physical activity, creative projects, social connection
- Each item max 65 characters

Return ONLY a valid JSON array of 3 strings. Nothing else.
Example: ["Learned the first 3 chords on guitar", "Walked to the park and back twice", "Wrote the opening chapter of a story"]''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'},
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an inspiring life coach. Give specific, time-calibrated alternatives. Respond ONLY with a valid JSON array of 3 strings.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 140,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body);
        final content = (data['choices'][0]['message']['content'] as String).trim();
        // Strip markdown code fences if present
        final cleaned = content
            .replaceAll(RegExp(r'^```[a-z]*\n?', multiLine: true), '')
            .replaceAll(RegExp(r'```$', multiLine: true), '')
            .trim();
        final decoded = jsonDecode(cleaned);
        List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          list = (decoded['items'] ??
              decoded['alternatives'] ??
              decoded['activities'] ??
              decoded.values.first) as List;
        } else {
          return _fallback(totalMinutes);
        }
        return list.take(3).map((e) => e.toString()).toList();
      }
    } catch (_) {}

    return _fallback(totalMinutes);
  }

  static List<String> _fallback(int totalMinutes) {
    final h = totalMinutes / 60.0;
    return [
      'Read ${(h * 25).round()} pages of a book you\'ve been putting off',
      'Walked ${(h * 4).round()}km and actually noticed the world around you',
      'Learned ${totalMinutes} minutes of a skill that compounds over time',
    ];
  }
}
