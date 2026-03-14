import 'opportunity.dart';

class ChatMessage {
  final String content;
  final String role;
  final DateTime timestamp;
  final List<Opportunity> opportunities;

  ChatMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.opportunities = const [],
  }) : timestamp = timestamp ?? DateTime.now();
}
