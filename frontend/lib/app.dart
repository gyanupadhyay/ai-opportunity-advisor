import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'constants.dart';
import 'pages/admin_page.dart';
import 'pages/chat_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/shared_chat_page.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(
          path: routeHome,
          title: '$appName — Scholarships, Internships & Global Opportunities',
          builder: (context, state) => const HomePage(),
        ),
        Route(
          path: routeLogin,
          title: 'Login - $appName',
          builder: (context, state) => const LoginPage(),
        ),
        Route(
          path: routeChat,
          title: 'Chat - $appName',
          builder: (context, state) => const ChatPage(),
        ),
        Route(
          path: '$routeShareChat/:id',
          title: 'Shared Chat - $appName',
          builder: (context, state) {
            final id = state.params['id'] ?? '';
            return SharedChatPage(id);
          },
        ),
        Route(
          path: routeAdmin,
          title: 'Admin - $appName',
          builder: (context, state) => const AdminPage(),
        ),
      ],
    );
  }
}
