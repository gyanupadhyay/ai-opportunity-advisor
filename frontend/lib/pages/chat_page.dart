import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;

import '../constants.dart';
import '../components/chat_widget.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ChatPage extends StatefulComponent {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _showLogoutConfirm = false;
  bool _sidebarOpen = false;
  bool _loadingConversations = true;

  List<Map<String, dynamic>> _conversations = [];
  String? _activeConversationId;
  bool _shareModalOpen = false;
  String? _shareLink;

  // Which conversation's 3-dot menu is open (if any).
  String? _openMenuConversationId;

  // Incremented to force ChatWidget rebuild when switching conversations
  int _chatKey = 0;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _loadingConversations = true);

    final convs = await ApiService.listConversations();

    setState(() {
      _conversations = convs;
      _activeConversationId = convs.isNotEmpty ? convs.first['id'] as String? : null;
      _loadingConversations = false;
      _chatKey++;
    });
  }

  Future<void> _createNewChat() async {
    final result = await ApiService.createConversation();
    if (result != null) {
      final id = result['id'] as String;
      setState(() {
        _conversations.insert(0, {
          'id': id,
          'title': result['title'] ?? 'New chat',
        });
        _activeConversationId = id;
        _sidebarOpen = false;
        _chatKey++;
      });
    }
  }

  void _selectConversation(String id) {
    if (id == _activeConversationId) {
      setState(() => _sidebarOpen = false);
      return;
    }
    setState(() {
      _activeConversationId = id;
      _sidebarOpen = false;
      _chatKey++;
    });
  }

  Future<void> _deleteConversation(String id) async {
    final success = await ApiService.deleteConversation(id);
    if (!success) return;

    setState(() {
      _conversations.removeWhere((c) => c['id'] == id);
      if (_openMenuConversationId == id) {
        _openMenuConversationId = null;
      }

      if (_activeConversationId == id) {
        _activeConversationId = _conversations.isNotEmpty ? _conversations.first['id'] as String? : null;
        _chatKey++;
      }
    });
  }

  Future<void> _shareActiveConversation() async {
    final id = _activeConversationId;
    if (id == null) return;

    final url = await ApiService.createShareLink(id);
    if (url == null) {
      // Simple fallback: show a minimal error in the modal.
      setState(() {
        _shareLink = null;
        _shareModalOpen = true;
      });
      return;
    }

    setState(() {
      _shareLink = url;
      _shareModalOpen = true;
    });
  }

  void _onTitleUpdated(String conversationId, String newTitle) {
    setState(() {
      final idx = _conversations.indexWhere((c) => c['id'] == conversationId);
      if (idx != -1) {
        _conversations[idx] = {..._conversations[idx], 'title': newTitle};
      }
    });
  }

  Future<void> _confirmAndSignOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    Router.of(context).push(routeHome);
  }

  @override
  Component build(BuildContext context) {
    final user = AuthService.currentUser;

    return div(classes: 'chat-page', [
      // ── Sidebar ──
      div(
        classes: 'chat-sidebar${_sidebarOpen ? ' open' : ''}',
        [
          div(classes: 'sidebar-header', [
            h3([.text('Chats')]),
            button(
              classes: 'sidebar-close-btn',
              onClick: () => setState(() => _sidebarOpen = false),
              [.text('\u00D7')],
            ),
          ]),
          button(
            classes: 'new-chat-btn',
            onClick: _createNewChat,
            [.text('\u002B  New chat')],
          ),
          div(classes: 'conversation-list', [
            if (_loadingConversations)
              div(classes: 'conv-loading', [.text('Loading...')])
            else
              for (final conv in _conversations) _buildConversationItem(conv),
          ]),
          if (user != null)
            div(classes: 'sidebar-footer', [
              div(classes: 'sidebar-user', [
                if (user.photoUrl.isNotEmpty)
                  img(
                    classes: 'sidebar-user-img',
                    src: user.photoUrl,
                    attributes: {'referrerpolicy': 'no-referrer'},
                  )
                else
                  span(classes: 'sidebar-user-icon', [.text('\u{1F464}')]),
                span(classes: 'sidebar-user-name', [
                  .text(user.name.isNotEmpty ? user.name : user.email),
                ]),
              ]),
            ]),
        ],
      ),

      // ── Sidebar overlay (mobile) ──
      if (_sidebarOpen)
        div(
          classes: 'sidebar-overlay',
          events: {
            'click': (_) => setState(() => _sidebarOpen = false),
          },
          [],
        ),

      // ── Main chat area ──
      div(classes: 'chat-main', [
        // Header
        div(classes: 'chat-header', [
          div(classes: 'chat-header-left', [
            button(
              classes: 'hamburger-btn',
              onClick: () => setState(() => _sidebarOpen = !_sidebarOpen),
              [.text('\u2630')],
            ),
            div(classes: 'chat-header-title', [
              span(classes: 'logo-icon', [.text('\u{1F9ED}')]),
              h2([.text(appName)]),
            ]),
          ]),
          div(classes: 'chat-header-actions', [
            if (_activeConversationId != null)
              button(
                classes: 'secondary-btn',
                onClick: _shareActiveConversation,
                [.text('Share chat')],
              ),
            if (user != null)
              button(
                classes: 'user-avatar-btn',
                onClick: () => setState(() => _showLogoutConfirm = true),
                [
                  if (user.photoUrl.isNotEmpty)
                    img(
                      classes: 'user-avatar-img',
                      src: user.photoUrl,
                      attributes: {'referrerpolicy': 'no-referrer'},
                    )
                  else
                    span([.text('\u{1F464}')]),
                  span(classes: 'user-avatar-name', [.text('Logout')]),
                ],
              ),
            Link(
              to: routeHome,
              child: span(classes: 'back-btn', [.text('\u{2190} Home')]),
            ),
          ]),
        ]),

        // Chat content
        if (_activeConversationId != null)
          ChatWidget(
            key: ValueKey('chat-$_chatKey'),
            conversationId: _activeConversationId!,
            onTitleUpdated: _onTitleUpdated,
          )
        else
          div(classes: 'chat-empty', [
            p([.text('Click "+ New chat" to start a conversation.')]),
          ]),
      ]),

      // ── Logout modal ──
      if (_showLogoutConfirm)
        div(classes: 'modal-backdrop', [
          div(classes: 'modal-card', [
            div(classes: 'modal-header', [
              h2([.text('Logout?')]),
              button(
                classes: 'modal-close-btn',
                onClick: () => setState(() => _showLogoutConfirm = false),
                [.text('\u00D7')],
              ),
            ]),
            div(classes: 'modal-body', [
              p([
                .text(
                  'You will be logged out of Vedixa AI. You can log in again at any time to continue exploring opportunities.',
                ),
              ]),
            ]),
            div(classes: 'modal-footer modal-footer-row', [
              button(
                classes: 'modal-secondary-btn',
                onClick: () => setState(() => _showLogoutConfirm = false),
                [.text('Cancel')],
              ),
              button(
                classes: 'modal-primary-btn modal-primary-btn--danger',
                onClick: () {
                  setState(() => _showLogoutConfirm = false);
                  _confirmAndSignOut();
                },
                [.text('Logout')],
              ),
            ]),
          ]),
        ]),

      // ── Share link modal ──
      if (_shareModalOpen)
        div(classes: 'modal-backdrop', [
          div(classes: 'modal-card', [
            div(classes: 'modal-header', [
              h2([.text('Share this chat')]),
              button(
                classes: 'modal-close-btn',
                onClick: () => setState(() => _shareModalOpen = false),
                [.text('\u00D7')],
              ),
            ]),
            div(classes: 'modal-body', [
              if (_shareLink == null)
                p([
                  .text(
                    'We could not generate a shareable link right now. Please try again in a moment.',
                  ),
                ])
              else
                div(classes: 'share-link-block', [
                  p([
                    .text(
                      'Anyone with this link can view a read-only copy of this conversation:',
                    ),
                  ]),
                  input(
                    attributes: {
                      'type': 'text',
                      'readonly': 'readonly',
                      'value': _shareLink!,
                    },
                    classes: 'share-link-input',
                  ),
                ]),
            ]),
            div(classes: 'modal-footer modal-footer-row', [
              button(
                classes: 'modal-secondary-btn',
                onClick: () => setState(() => _shareModalOpen = false),
                [.text('Close')],
              ),
            ]),
          ]),
        ]),

    ]);
  }

  Component _buildConversationItem(Map<String, dynamic> conv) {
    final id = conv['id'] as String;
    final title = (conv['title'] as String?) ?? 'New chat';
    final isActive = id == _activeConversationId;

    return div(
      classes: 'conv-item${isActive ? ' active' : ''}',
      [
        button(
          classes: 'conv-item-btn',
          onClick: () => _selectConversation(id),
          [
            span(classes: 'conv-item-icon', [.text('\u{1F4AC}')]),
            span(classes: 'conv-item-title', [.text(title)]),
          ],
        ),
        div(classes: 'conv-item-menu-wrapper', [
          button(
            classes: 'conv-item-menu',
            onClick: () => setState(() {
              _openMenuConversationId =
                  _openMenuConversationId == id ? null : id;
            }),
            [.text('\u22EE')],
          ),
          if (_openMenuConversationId == id)
            div(classes: 'conv-item-menu-popover', [
              button(
                classes: 'conv-item-menu-item',
                onClick: () async {
                  final current = title;
                  final newName = web.window
                      .prompt('Edit chat name', current)
                      ?.trim();
                  if (newName == null || newName.isEmpty) return;

                  final ok =
                      await ApiService.renameConversation(id, newName);
                  if (!ok) return;

                  setState(() {
                    final idx =
                        _conversations.indexWhere((c) => c['id'] == id);
                    if (idx != -1) {
                      _conversations[idx] = {
                        ..._conversations[idx],
                        'title': newName,
                      };
                    }
                    _openMenuConversationId = null;
                  });
                },
                [.text('Edit name')],
              ),
              button(
                classes: 'conv-item-menu-item conv-item-menu-item--danger',
                onClick: () async {
                  final confirm = web.window.confirm(
                    'Delete this chat and all its messages?',
                  );
                  if (!confirm) return;
                  await _deleteConversation(id);
                  setState(() {
                    _openMenuConversationId = null;
                  });
                },
                [.text('Delete')],
              ),
            ]),
        ]),
      ],
    );
  }
}
