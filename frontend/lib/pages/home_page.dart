import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants.dart';

class HomePage extends StatelessComponent {
  const HomePage({super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'landing-page', [
      div(classes: 'landing-content', [
        div(classes: 'landing-icon', [.text('\u{1F9ED}')]),
        h1(classes: 'landing-title', [.text(appName)]),
        p(classes: 'landing-description', [
          .text(
            'Your AI-powered guide to scholarships, internships, fellowships, '
            'research programs, and global opportunities \u{2014} '
            'tailored to your goals.',
          ),
        ]),
        div(classes: 'landing-features', [
          span(classes: 'feature-tag', [.text('\u{1F3AF} Scholarships')]),
          span(classes: 'feature-tag', [.text('\u{1F4BC} Internships')]),
          span(classes: 'feature-tag', [.text('\u{1F3C6} Fellowships')]),
          span(classes: 'feature-tag', [.text('\u{1F52C} Research Programs')]),
          span(classes: 'feature-tag', [.text('\u{1F30D} Global Summits')]),
          span(classes: 'feature-tag', [.text('\u{2708}\u{FE0F} Exchange Programs')]),
        ]),
        Link(
          to: routeChat,
          child: span(classes: 'start-chat-btn', [
            .text('Start Exploring \u{2192}'),
          ]),
        ),
      ]),
    ]);
  }
}
