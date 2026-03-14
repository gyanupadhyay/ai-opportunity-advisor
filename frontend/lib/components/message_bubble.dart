import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import 'opportunity_card.dart';

class MessageBubble extends StatelessComponent {
  final ChatMessage message;

  const MessageBubble({required this.message, super.key});

  @override
  Component build(BuildContext context) {
    final isUser = message.role == roleUser;
    final user = AuthService.currentUser;
    final hasPhoto = isUser && user != null && user.photoUrl.isNotEmpty;

    return div(classes: 'message-row ${message.role}', [
      div(classes: 'message-avatar', [
        if (hasPhoto)
          img(
            classes: 'user-avatar-img',
            src: user!.photoUrl,
            attributes: {'referrerpolicy': 'no-referrer'},
          )
        else
          .text(isUser ? '\u{1F464}' : '\u{1F9ED}'),
      ]),
      div(classes: 'message-content', [
        div(classes: 'message-bubble', [.text(message.content)]),
        if (message.opportunities.isNotEmpty)
          div(classes: 'opportunities-grid', [
            for (final opp in message.opportunities)
              OpportunityCard(opportunity: opp),
          ]),
      ]),
    ]);
  }
}
