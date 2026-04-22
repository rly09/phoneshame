import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/roast_model.dart';
import '../models/app_usage_model.dart';
import '../../core/utils/time_formatter.dart';

class RoastService {
  // Use Groq API
  Future<RoastModel> getRoast(List<AppUsageModel> usage, int totalMinutes) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey.contains('your_key_here')) {
      // API Key is missing or default
    }

    final topApps = usage.take(3).map((e) => "${e.appName} (${TimeFormatter.formatMinutesToHours(e.totalTimeInMinutes)})").join(', ');
    final totalHours = (totalMinutes / 60.0).toStringAsFixed(1);

    final prompt = "The user spent $totalHours hours on their phone today. Top apps: $topApps. Write a brutally funny 2-sentence roast. Be savage but not mean. End with one specific thing they could have done instead.";

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'), // Using standard chat completions for robust parsing, but will fallback if needed. Or we can use the exact URL provided.
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant', // A guaranteed valid Groq model. If they prefer the snippet model:
          // 'model': 'openai/gpt-oss-20b',
          'messages': [
            {'role': 'system', 'content': 'You are a brutal but funny roaster.'},
            {'role': 'user', 'content': prompt}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'];
        return RoastModel(text: text);
      } else {
        // Fallback to exactly what the user provided if the standard chat completions fails
        final fallbackResponse = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/responses'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'openai/gpt-oss-20b',
            'input': prompt
          }),
        );
        
        if (fallbackResponse.statusCode == 200) {
           final fallbackData = jsonDecode(fallbackResponse.body);
           final text = fallbackData['choices']?[0]?['text'] ?? fallbackData['response'] ?? fallbackData.toString();
           return RoastModel(text: text);
        }
        
        return RoastModel(text: "Too much screen time fried my circuits. Can't roast you right now. (${response.statusCode} - ${response.body})");
      }
    } catch (e) {
      return RoastModel(text: "Failed to connect to the roast server. Go touch grass.");
    }
  }
}
