import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants.dart';
import '../components/chat_widget.dart';
import '../services/auth_service.dart';

class ChatPage extends StatefulComponent {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<void> _handleSignOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    Router.of(context).push(routeHome);
  }

  @override
  Component build(BuildContext context) {
    final user = AuthService.currentUser;

    return div(classes: 'chat-page', [
      div(classes: 'chat-header', [
        div(classes: 'chat-header-title', [
          span(classes: 'logo-icon', [.text('\u{1F9ED}')]),
          h2([.text(appName)]),
        ]),
        div(classes: 'chat-header-actions', [
          if (user != null)
            button(
              classes: 'user-avatar-btn',
              onClick: _handleSignOut,
              [
                if (user.photoUrl.isNotEmpty)
                  img(
                    classes: 'user-avatar-img',
                    src: user.photoUrl,
                    attributes: {'referrerpolicy': 'no-referrer'},
                  )
                else
                  span([.text('\u{1F464}')]),
                span(classes: 'user-avatar-name', [
                  .text('Logout'),
                ]),
              ],
            ),
          Link(
            to: routeHome,
            child: span(classes: 'back-btn', [.text('\u{2190} Home')]),
          ),
        ]),
      ]),
      const ChatWidget(),
    ]);
  }
}
