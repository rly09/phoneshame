import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/roast_model.dart';
import '../models/app_usage_model.dart';
import '../../core/utils/time_formatter.dart';

class RoastService {
  // Use Anthropic API
  Future<RoastModel> getRoast(List<AppUsageModel> usage, int totalMinutes) async {
    final apiKey = dotenv.env['ANTHROPIC_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_key_here') {
      return RoastModel(text: "You wasted so much time, you forgot to set up your API key. Classic.");
    }

    final topApps = usage.take(3).map((e) => "${e.appName} (${TimeFormatter.formatMinutesToHours(e.totalTimeInMinutes)})").join(', ');
    final totalHours = (totalMinutes / 60.0).toStringAsFixed(1);

    final prompt = "The user spent $totalHours hours on their phone today. Top apps: $topApps. Write a brutally funny 2-sentence roast. Be savage but not mean. End with one specific thing they could have done instead.";

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 150,
          'messages': [
            {'role': 'user', 'content': prompt}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'];
        return RoastModel(text: text);
      } else {
        return RoastModel(text: "Too much screen time fried my circuits. Can't roast you right now. (${response.statusCode})");
      }
    } catch (e) {
      return RoastModel(text: "Failed to connect to the roast server. Go touch grass.");
    }
  }
}
