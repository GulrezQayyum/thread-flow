// lib/providers/ai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/groq_service.dart';

// Simple cache map for summaries
Map<String, String> _summaryCache = {};

final groqServiceProvider = Provider((ref) => GroqService());

// Generate summary for messages
final generateSummaryProvider = FutureProvider.family<String, GenerateSummaryParams>(
  (ref, params) async {
    print('🤖 PROVIDER: Generating summary for ${params.messages.length} messages');
    
    try {
      final groq = ref.watch(groqServiceProvider);

      if (!groq.isConfigured) {
        print('⚠️ PROVIDER: Groq API not configured');
        return '';
      }

      if (params.messages.length < 3) {
        print('⚠️ PROVIDER: Not enough messages (${params.messages.length} < 3)');
        return '';
      }

      final cacheKey = '${params.chatId}_${params.messages.length}_${params.messages.last.id}';
      
      if (_summaryCache.containsKey(cacheKey)) {
        print('✅ PROVIDER: Using cached summary');
        return _summaryCache[cacheKey]!;
      }

      print('📡 PROVIDER: Calling Groq API...');
      
      final summary = await groq.generateThreadSummary(params.messages);
      
      if (summary.isNotEmpty) {
        _summaryCache[cacheKey] = summary;
        print('✅ PROVIDER: Summary generated and cached: "$summary"');
      }
      
      return summary;
    } catch (e) {
      print('❌ PROVIDER SUMMARY ERROR: $e');
      return '';
    }
  },
);

class GenerateSummaryParams {
  final String chatId;
  final List<MessageModel> messages;
  final String? threadId;

  GenerateSummaryParams({
    required this.chatId,
    required this.messages,
    this.threadId,
  });
}

// Generate thread title
final generateTitleProvider = FutureProvider.family<String, List<MessageModel>>(
  (ref, messages) async {
    print('🤖 PROVIDER: Generating thread title...');
    
    try {
      if (messages.isEmpty) {
        print('⚠️ PROVIDER: No messages to generate title from');
        return '';
      }

      final groq = ref.watch(groqServiceProvider);

      if (!groq.isConfigured) {
        print('⚠️ PROVIDER: Groq API not configured');
        return '';
      }

      final title = await groq.generateThreadTitle(messages);
      print('✅ PROVIDER: Title generated: "$title"');
      return title;
    } catch (e) {
      print('❌ PROVIDER TITLE ERROR: $e');
      return '';
    }
  },
);

// Analyze sentiment
final analyzeSentimentProvider = FutureProvider.family<String, List<MessageModel>>(
  (ref, messages) async {
    print('🤖 PROVIDER: Analyzing sentiment...');
    
    try {
      if (messages.isEmpty) {
        print('⚠️ PROVIDER: No messages to analyze');
        return 'neutral';
      }

      final groq = ref.watch(groqServiceProvider);

      if (!groq.isConfigured) {
        print('⚠️ PROVIDER: Groq API not configured');
        return 'neutral';
      }

      final sentiment = await groq.analyzeSentiment(messages);
      print('✅ PROVIDER: Sentiment analyzed: $sentiment');
      return sentiment;
    } catch (e) {
      print('❌ PROVIDER SENTIMENT ERROR: $e');
      return 'neutral';
    }
  },
);

// Extract keywords
final extractKeywordsProvider = FutureProvider.family<List<String>, List<MessageModel>>(
  (ref, messages) async {
    print('🤖 PROVIDER: Extracting keywords...');
    
    try {
      if (messages.isEmpty) {
        print('⚠️ PROVIDER: No messages to extract from');
        return [];
      }

      final groq = ref.watch(groqServiceProvider);

      if (!groq.isConfigured) {
        print('⚠️ PROVIDER: Groq API not configured');
        return [];
      }

      final keywords = await groq.extractKeywords(messages);
      print('✅ PROVIDER: Keywords extracted: $keywords');
      return keywords;
    } catch (e) {
      print('❌ PROVIDER KEYWORDS ERROR: $e');
      return [];
    }
  },
);

// Get suggested reply
final suggestedReplyProvider = FutureProvider.family<String, List<MessageModel>>(
  (ref, messages) async {
    print('🤖 PROVIDER: Getting suggested reply...');
    
    try {
      if (messages.isEmpty) {
        print('⚠️ PROVIDER: No messages for suggestion');
        return '';
      }

      final groq = ref.watch(groqServiceProvider);

      if (!groq.isConfigured) {
        print('⚠️ PROVIDER: Groq API not configured');
        return '';
      }

      final reply = await groq.generateSuggestedReply(messages);
      print('✅ PROVIDER: Reply suggested: "$reply"');
      return reply;
    } catch (e) {
      print('❌ PROVIDER REPLY ERROR: $e');
      return '';
    }
  },
);

// Check if Groq API is configured
final groqConfiguredProvider = Provider<bool>((ref) {
  final groq = ref.watch(groqServiceProvider);
  return groq.isConfigured;
});

// Check Groq API status
final groqStatusProvider = FutureProvider<bool>((ref) async {
  print('🔍 PROVIDER: Checking Groq API status...');
  
  try {
    final groq = ref.watch(groqServiceProvider);
    
    if (!groq.isConfigured) {
      print('⚠️ PROVIDER: Groq not configured');
      return false;
    }

    final status = await groq.checkApiStatus();
    print('✅ PROVIDER: Groq API status: $status');
    return status;
  } catch (e) {
    print('❌ PROVIDER STATUS ERROR: $e');
    return false;
  }
});

// Get Groq configuration info
final groqInfoProvider = Provider<String>((ref) {
  final groq = ref.watch(groqServiceProvider);
  return groq.getApiInfo();
});