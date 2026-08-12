// lib/widgets/summary_banner.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/message_model.dart';
import '../../providers/ai_provider.dart';
import '../../config/groq_config.dart';

class SummaryBanner extends ConsumerStatefulWidget {
  final String chatId;
  final List<MessageModel> messages;

  const SummaryBanner({
    Key? key,
    required this.chatId,
    required this.messages,
  }) : super(key: key);

  @override
  ConsumerState<SummaryBanner> createState() => _SummaryBannerState();
}

class _SummaryBannerState extends ConsumerState<SummaryBanner> {
  bool _hasGenerated = false;
  String? _cachedSummary;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isExpanded = false; // ← ADD THIS

  @override
  void initState() {
    super.initState();
    _generateSummaryOnce();
  }

  Future<void> _generateSummaryOnce() async {
    if (_hasGenerated) return;
    
    final userMessages = widget.messages.where((m) => m.messageType != 'ai_summary').toList();
    
    if (userMessages.length < 2) {
      return;
    }

    _hasGenerated = true;
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await ref.read(
        generateSummaryProvider(
          GenerateSummaryParams(
            chatId: widget.chatId,
            messages: userMessages,
          ),
        ).future,
      );

      if (mounted) {
        setState(() {
          _cachedSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMessages = widget.messages.where((m) => m.messageType != 'ai_summary').toList();
    
    final isConfigured = ref.watch(groqConfiguredProvider);

    if (!isConfigured || userMessages.length < 2) {
      return const SizedBox.shrink();
    }

    if (_hasError) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Generating AI summary...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      );
    }

    if (_cachedSummary != null && _cachedSummary!.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI Summary',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const Spacer(),
                            // Tap indicator
                            Icon(
                              _isExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _cachedSummary!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Sentiment indicator
                  Consumer(
                    builder: (context, ref, _) {
                      final sentimentAsync = ref.watch(
                        analyzeSentimentProvider(userMessages),
                      );
                      return sentimentAsync.when(
                        data: (sentiment) {
                          IconData icon;
                          Color color;
                          switch (sentiment) {
                            case 'positive':
                              icon = Icons.sentiment_very_satisfied;
                              color = Colors.green;
                              break;
                            case 'negative':
                              icon = Icons.sentiment_very_dissatisfied;
                              color = Colors.red;
                              break;
                            default:
                              icon = Icons.sentiment_neutral;
                              color = Colors.grey;
                          }
                          return Icon(icon, size: 16, color: color);
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
              // Expand/Collapse hint
              if (!_isExpanded) ...[
                const SizedBox(height: 4),
                Text(
                  'Tap to expand...',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}