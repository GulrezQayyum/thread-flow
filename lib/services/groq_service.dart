// lib/services/groq_service.dart - IMPROVED PROMPT ENGINEERING
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message_model.dart';

class GroqService {
  final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  final String apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String model = 'llama-3.3-70b-versatile';

  GroqService() {
    if (apiKey.isEmpty) {
      print('⚠️ GROQ: API key not found in .env');
    } else {
      print('✅ GROQ: API key loaded');
    }
  }

  /// Generate summary with IMPROVED prompt engineering
  Future<String> generateThreadSummary(List<MessageModel> messages) async {
    try {
      if (messages.isEmpty) {
        print('⚠️ GROQ: No messages to summarize');
        return '';
      }

      print('🤖 GROQ: Generating summary for ${messages.length} messages');

      // Better message formatting with context
      final formattedMessages = messages
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key + 1;
            final message = entry.value;
            return 'Message $index: "${message.text}"';
          })
          .join('\n');

      // Improved prompt with better instructions
      final prompt =
          '''You are a conversation analyst. Analyze the following conversation thread and create a concise, meaningful summary.

CONVERSATION:
$formattedMessages

INSTRUCTIONS:
1. Identify the main topic or theme of the conversation
2. Capture the key discussion points
3. Write summary in 1-2 sentences maximum
4. Be specific and avoid generic phrases
5. Focus on WHAT is being discussed, not just listing words
6. Use natural language that captures the essence of the discussion

SUMMARY:''';

      final summary = await _callGroqAPI(prompt);

      if (summary.isEmpty) {
        print('⚠️ GROQ: Empty summary returned');
        return 'No summary available';
      }

      print('✅ GROQ: Summary generated: "$summary"');
      return summary.trim();
    } catch (e) {
      print('❌ GROQ SUMMARY ERROR: $e');
      return '';
    }
  }

  /// Generate a thread title with improved prompt
  Future<String> generateThreadTitle(List<MessageModel> messages) async {
    try {
      if (messages.isEmpty) return '';

      print('🤖 GROQ: Generating thread title');

      final messageTexts = messages.map((m) => m.text).join(' ');

      final prompt =
          '''Based on this conversation, generate a SHORT thread title (3-5 words maximum).
The title should capture the main topic being discussed.

Conversation: $messageTexts

Respond with ONLY the title, nothing else.

Title:''';

      final title = await _callGroqAPI(prompt);
      print('✅ GROQ: Title generated: "$title"');
      return title.trim();
    } catch (e) {
      print('❌ GROQ TITLE ERROR: $e');
      return '';
    }
  }

  /// Analyze sentiment with better prompt
  Future<String> analyzeSentiment(List<MessageModel> messages) async {
    try {
      if (messages.isEmpty) return 'neutral';

      print('🤖 GROQ: Analyzing sentiment');

      final messageTexts = messages.map((m) => '- "${m.text}"').join('\n');

      final prompt =
          '''Analyze the overall sentiment of this conversation.
Respond with ONLY ONE WORD: positive, negative, or neutral.

Messages:
$messageTexts

Sentiment (one word only):''';

      final sentiment = await _callGroqAPI(prompt);
      final normalized = sentiment.toLowerCase().trim();

      if (normalized.contains('positive')) return 'positive';
      if (normalized.contains('negative')) return 'negative';
      return 'neutral';
    } catch (e) {
      print('❌ GROQ SENTIMENT ERROR: $e');
      return 'neutral';
    }
  }

  /// Extract keywords with better prompt
  Future<List<String>> extractKeywords(List<MessageModel> messages) async {
    try {
      if (messages.isEmpty) return [];

      print('🤖 GROQ: Extracting keywords');

      final messageTexts = messages.map((m) => m.text).join(' ');

      final prompt =
          '''Extract the 3-5 most important keywords or topics from this conversation.
Return ONLY comma-separated keywords.
No explanations, no numbering, just keywords.

Conversation: $messageTexts

Keywords:''';

      final response = await _callGroqAPI(prompt);
      final keywords = response
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty && k.length > 1)
          .take(5)
          .toList();

      print('✅ GROQ: Keywords extracted: $keywords');
      return keywords;
    } catch (e) {
      print('❌ GROQ KEYWORDS ERROR: $e');
      return [];
    }
  }

  /// Generate suggested reply
  Future<String> generateSuggestedReply(List<MessageModel> messages) async {
    try {
      if (messages.isEmpty) return '';

      print('🤖 GROQ: Generating suggested reply');

      final lastMessage = messages.last.text;
      final context = messages.length > 1
          ? messages.sublist(messages.length - 3).map((m) => m.text).join(' | ')
          : '';

      final prompt =
          '''Based on this conversation, suggest ONE helpful reply to the last message.
Keep the suggestion short and natural.

Context: $context
Last message: "$lastMessage"

Suggested reply:''';

      final suggestion = await _callGroqAPI(prompt);
      print('✅ GROQ: Suggestion generated: "$suggestion"');
      return suggestion.trim();
    } catch (e) {
      print('❌ GROQ SUGGESTION ERROR: $e');
      return '';
    }
  }

  /// Core API call with IMPROVED error handling
  Future<String> _callGroqAPI(String prompt) async {
    try {
      if (apiKey.isEmpty) {
        throw Exception(
          'Groq API key not configured. Add GROQ_API_KEY to .env',
        );
      }

      print('📡 GROQ: Calling API...');
      print('📡 GROQ: Model: $model');

      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a helpful AI assistant for conversation analysis. Provide concise, accurate, and meaningful responses.',
                },
              ],
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.5,
              'max_tokens': 150,
              'top_p': 0.9,
              'stream': false,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 GROQ: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['choices'] == null || data['choices'].isEmpty) {
          print('❌ GROQ: No choices in response');
          return '';
        }

        final content = data['choices'][0]['message']['content']
            .toString()
            .trim();
        print('✅ GROQ: API call successful, response: "$content"');
        return content;
      } else if (response.statusCode == 401) {
        print('❌ GROQ: Invalid API key (401)');
        throw Exception(
          'Invalid Groq API key. Check your GROQ_API_KEY in .env',
        );
      } else if (response.statusCode == 429) {
        print('⚠️ GROQ: Rate limited (429) - Free tier: 30 req/min');
        throw Exception('Groq API rate limited. Wait a minute and try again.');
      } else if (response.statusCode == 500) {
        print('❌ GROQ: Server error (500)');
        throw Exception('Groq API server error. Try again later.');
      } else {
        print('❌ GROQ: API error ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GROQ API ERROR: $e');
      rethrow;
    }
  }

  /// Check if API is configured
  bool get isConfigured => apiKey.isNotEmpty;

  /// Get API status with better error handling
  Future<bool> checkApiStatus() async {
    try {
      print('🔍 GROQ: Checking API status...');
      final test = await _callGroqAPI('Say "API is working" - this is a test.');
      final working = test.isNotEmpty;
      print('✅ GROQ: API status check complete: $working');
      return working;
    } catch (e) {
      print('❌ GROQ: API status check failed: $e');
      return false;
    }
  }

  /// Get API info
  String getApiInfo() {
    return '''
Groq API Configuration:
- Model: $model
- API Key: ${apiKey.isNotEmpty ? 'Configured ✅' : 'Not configured ❌'}
- Max Tokens: 150
- Temperature: 0.5
- Rate Limit: 30 req/min (Free tier)
    ''';
  }
}
