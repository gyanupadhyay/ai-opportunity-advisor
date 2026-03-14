import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../models/message.dart';
import 'opportunity_card.dart';

class MessageBubble extends StatelessComponent {
  final ChatMessage message;

  const MessageBubble({required this.message, super.key});

  @override
  Component build(BuildContext context) {
    final isUser = message.role == 'user';

    return div(classes: 'message-row ${message.role}', [
      div(classes: 'message-avatar', [
        .text(isUser ? '\u{1F464}' : '\u{1F9ED}'),
      ]),
      div(classes: 'message-content', [
        div(classes: 'message-bubble', [.text(message.content)]),
        if (message.opportunities.isNotEmpty)
          div(classes: 'opportunities-grid', [
            for (final opp in message.opportunities) OpportunityCard(opportunity: opp),
          ]),
      ]),
    ]);
  }
}
