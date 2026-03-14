import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../components/chat_widget.dart';

class ChatPage extends StatelessComponent {
  const ChatPage({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'chat-page', [
      div(classes: 'chat-header', [
        div(classes: 'chat-header-title', [
          span(classes: 'logo-icon', [.text('\u{1F9ED}')]),
          h2([.text('Pathora AI')]),
        ]),
        Link(
          to: '/',
          child: span(classes: 'back-btn', [.text('\u{2190} Home')]),
        ),
      ]),
      const ChatWidget(),
    ]);
  }
}
