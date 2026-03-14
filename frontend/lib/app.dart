import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'pages/admin_page.dart';
import 'pages/chat_page.dart';
import 'pages/home_page.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(
          path: '/',
          title: 'AI Opportunity Advisor',
          builder: (context, state) => const HomePage(),
        ),
        Route(
          path: '/chat',
          title: 'Chat - AI Opportunity Advisor',
          builder: (context, state) => const ChatPage(),
        ),
        Route(
          path: '/admin',
          title: 'Admin - AI Opportunity Advisor',
          builder: (context, state) => const AdminPage(),
        ),
      ],
    );
  }
}
