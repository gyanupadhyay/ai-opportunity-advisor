import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulComponent {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  String? _error;
  String? _activeLegal; // 'terms' or 'privacy'

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await AuthService.signInWithGoogle();

    if (success) {
      // Small delay to let localStorage sync from JS
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Router.of(context).push(routeChat);
    } else {
      setState(() {
        _loading = false;
        _error = 'Sign-in was cancelled or failed. Please try again.';
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'login-page', [
      div(classes: 'login-card', [
        div(classes: 'login-logo', [.text('\u{1F9ED}')]),
        h1(classes: 'login-title', [.text(appName)]),
        p(classes: 'login-subtitle', [
          .text(
            'Log in to discover scholarships, internships, '
            'and global opportunities tailored to your goals.',
          ),
        ]),
        div(classes: 'login-divider', []),
        button(
          classes: 'google-sign-in-btn${_loading ? ' loading' : ''}',
          disabled: _loading,
          onClick: _handleGoogleSignIn,
          [
            if (!_loading) ...[
              span(classes: 'google-icon', [
                raw('''<svg viewBox="0 0 24 24" width="20" height="20">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/>
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
                </svg>'''),
              ]),
              .text('Continue with Google'),
            ] else ...[
              span(classes: 'login-spinner', []),
              .text('Signing in...'),
            ],
          ],
        ),
        if (_error != null)
          p(classes: 'login-error', [.text(_error!)]),
        div(classes: 'login-footer', [
          p(classes: 'login-terms', [
            .text('By logging in you agree to our '),
            span(
              classes: 'login-link',
              events: {
                'click': (_) {
                  setState(() => _activeLegal = 'terms');
                },
              },
              [.text('Terms')],
            ),
            .text(' and '),
            span(
              classes: 'login-link',
              events: {
                'click': (_) {
                  setState(() => _activeLegal = 'privacy');
                },
              },
              [.text('Privacy Policy')],
            ),
          ]),
        ]),
        div(classes: 'login-skip', [
          Link(
            to: routeHome,
            child: span(classes: 'login-skip-link', [
              .text('\u{2190} Back to home'),
            ]),
          ),
        ]),
      ]),
      if (_activeLegal != null)
        div(classes: 'modal-backdrop', [
          div(classes: 'modal-card', [
            div(classes: 'modal-header', [
              h2([
                .text(
                  _activeLegal == 'terms' ? 'Terms of Use' : 'Privacy Policy',
                ),
              ]),
              button(
                classes: 'modal-close-btn',
                onClick: () => setState(() => _activeLegal = null),
                [.text('\u00D7')],
              ),
            ]),
            div(classes: 'modal-body', [
              if (_activeLegal == 'terms') ...[
                p([
                  .text(
                    'Vedixa AI is an informational assistant that helps you discover ',
                  ),
                ]),
                p([
                  .text(
                    'scholarships, internships, and global opportunities. Always verify ',
                  ),
                ]),
                p([
                  .text(
                    'details on the official opportunity website before applying. Using ',
                  ),
                ]),
                p([
                  .text(
                    'this site does not create any legal, financial, or advisory ',
                  ),
                ]),
                p([.text('relationship between you and Vedixa AI.')]),
              ] else ...[
                p([
                  .text(
                    'We store your conversation data and basic profile information ',
                  ),
                ]),
                p([
                  .text(
                    '(such as country, education level, and fields of interest) to ',
                  ),
                ]),
                p([
                  .text(
                    'personalise recommendations. We may also log technical data such ',
                  ),
                ]),
                p([
                  .text(
                    'as browser type and IP address for security and analytics. ',
                  ),
                ]),
                p([
                  .text(
                    'You can stop using the service at any time; your data can be ',
                  ),
                ]),
                p([.text('removed if you contact the project owner.')]),
              ],
            ]),
            div(classes: 'modal-footer', [
              button(
                classes: 'modal-primary-btn',
                onClick: () => setState(() => _activeLegal = null),
                [.text('Close')],
              ),
            ]),
          ]),
        ]),
    ]);
  }
}
