import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../components/message_bubble.dart';

class SharedChatPage extends StatefulComponent {
  final String shareId;

  const SharedChatPage(this.shareId, {super.key});

  @override
  State<SharedChatPage> createState() => _SharedChatPageState();
}

class _SharedChatPageState extends State<SharedChatPage> {
  final List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await ApiService.loadSharedConversation(component.shareId);
    setState(() {
      _messages.clear();
      _messages.addAll(
        raw.map(
          (m) => ChatMessage(content: m['content']!, role: m['role']!),
        ),
      );
      _loading = false;
    });
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'chat-page', [
      div(classes: 'chat-main', [
        div(classes: 'chat-header', [
          div(classes: 'chat-header-left', [
            div(classes: 'chat-header-title', [
              span(classes: 'logo-icon', [.text('\u{1F9ED}')]),
              h2([.text('$appName — Shared Chat')]),
            ]),
          ]),
          Link(
            to: routeHome,
            child: span(classes: 'back-btn', [.text('\u2190 Back to Vedixa')]),
          ),
        ]),
        if (_loading)
          div(
            classes: 'chat-empty',
            [p([.text('Loading shared conversation...')])],
          )
        else if (_messages.isEmpty)
          div(
            classes: 'chat-empty',
            [p([.text('This shared conversation is empty or no longer available.')])],
          )
        else
          div(classes: 'chat-messages', [
            for (final msg in _messages) MessageBubble(message: msg),
          ]),
      ]),
    ]);
  }
}

