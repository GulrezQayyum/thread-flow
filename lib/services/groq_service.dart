import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/groq_config.dart';
import '../models/message_model.dart';

class GroqService {
  Future<String> generateThreadSummary(List<MessageModel> messages) async {
    if (messages.isEmpty) {
      return 'Empty thread';
    }

    try {
      // Build conversation context
      final conversationText = messages
          .map((msg) => '- ${msg.text}')
          .join('\n');

      // Craft prompt for summarization
      final prompt = '''You are a helpful assistant that summarizes chat conversations concisely.
Summarize the following chat thread in 1-2 sentences, capturing the main topic and key points:

$conversationText

Summary:''';

      // Call Groq API
      final response = await http.post(
        Uri.parse('${GroqConfig.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': GroqConfig.model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': GroqConfig.maxTokens,
          'temperature': GroqConfig.temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['choices'][0]['message']['content'].toString().trim();
        return summary;
      } else if (response.statusCode == 401) {
        throw Exception('Groq API key is invalid. Check your .env file.');
      } else if (response.statusCode == 429) {
        throw Exception('Groq API rate limit exceeded. Try again later.');
      } else {
        throw Exception(
          'Failed to generate summary: ${response.statusCode} - ${response.body}'
        );
      }
    } catch (e) {
      // Graceful fallback
      if (messages.isNotEmpty) {
        final firstMsg = messages.first.text;
        final preview = firstMsg.length > 50
            ? '${firstMsg.substring(0, 50)}...'
            : firstMsg;
        return preview;
      }
      throw Exception('Error generating summary: $e');
    }
  }

  // Generate thread title from first message
  Future<String> generateThreadTitle(String firstMessage) async {
    try {
      final prompt = '''Extract a short title (max 5 words) for this chat message:
"$firstMessage"

Title:''';

      final response = await http.post(
        Uri.parse('${GroqConfig.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': GroqConfig.model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 50,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['choices'][0]['message']['content'].toString().trim();
        return title;
      } else {
        // Fallback to first 40 chars
        return firstMessage.length > 40
            ? '${firstMessage.substring(0, 40)}...'
            : firstMessage;
      }
    } catch (e) {
      // Graceful fallback
      return firstMessage.length > 40
          ? '${firstMessage.substring(0, 40)}...'
          : firstMessage;
    }
  }

  // Classify message sentiment (positive/neutral/negative)
  Future<String> classifyMessageSentiment(String text) async {
    try {
      final prompt = '''Classify the sentiment of this message as one word: positive, neutral, or negative.
Message: "$text"

Classification:''';

      final response = await http.post(
        Uri.parse('${GroqConfig.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': GroqConfig.model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 20,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sentiment = data['choices'][0]['message']['content'].toString().trim().toLowerCase();
        if (sentiment.contains('positive')) return 'positive';
        if (sentiment.contains('negative')) return 'negative';
        return 'neutral';
      } else {
        return 'neutral';
      }
    } catch (e) {
      return 'neutral';
    }
  }

  // Extract keywords from thread
  Future<List<String>> extractKeywords(List<MessageModel> messages) async {
    if (messages.isEmpty) return [];

    try {
      final conversationText = messages
          .map((msg) => msg.text)
          .join(' ');

      final prompt = '''Extract 3-5 key topics/keywords from this conversation (comma-separated):

"$conversationText"

Keywords:''';

      final response = await http.post(
        Uri.parse('${GroqConfig.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': GroqConfig.model,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'max_tokens': 100,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString().trim();
        return content.split(',').map((k) => k.trim()).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}