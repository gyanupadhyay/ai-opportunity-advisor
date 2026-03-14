import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../constants.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'chat_input_bar.dart';
import 'message_bubble.dart';

class ChatWidget extends StatefulComponent {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final GlobalNodeKey<web.HTMLDivElement> _messagesKey = GlobalNodeKey();

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  /// Sends a hidden "__start__" message so the Pathora AI advisor generates
  /// its opening greeting and first onboarding question.
  Future<void> _startConversation() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.sendMessage(startMessage);
      final user = AuthService.currentUser;
      var reply = response.reply;

      if (user != null && user.name.isNotEmpty) {
        final first = user.name.split(' ').first;
        reply = 'Hi $first,\n\n$reply';
      }

      setState(() {
        _messages.add(
          ChatMessage(
            content: reply,
            role: roleAssistant,
            opportunities: response.opportunities,
          ),
        );
        _isLoading = false;
      });
    } catch (_) {
      final user = AuthService.currentUser;
      final greeting = (user != null && user.name.isNotEmpty)
          ? 'Hi ${user.name.split(' ').first}!'
          : 'Hi there!';

      setState(() {
        _messages.add(
          ChatMessage(
            content:
                '$greeting I\u{2019}m Pathora AI, your personal guide to '
                'discovering scholarships, internships, fellowships, and global '
                'opportunities.\n\n'
                'Let\u{2019}s start \u{2014} which country are you from?',
            role: roleAssistant,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 60), () {
      final container = _messagesKey.currentNode;
      if (container != null) {
        container.scrollTo(
          web.ScrollToOptions(
            top: container.scrollHeight.toDouble(),
            behavior: 'smooth',
          ),
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(content: text, role: roleUser));
      _isLoading = true;
    });

    _scrollToBottom();

    final response = await ApiService.sendMessage(text);

    setState(() {
      _messages.add(
        ChatMessage(
          content: response.reply,
          role: roleAssistant,
          opportunities: response.opportunities,
        ),
      );
      _isLoading = false;
    });

    _scrollToBottom();
  }

  static const _quickReplyMap = <String, List<String>>{
    'education level': ['High School', 'Undergraduate', 'Masters', 'PhD'],
    'what level': ['High School', 'Undergraduate', 'Masters', 'PhD'],
    'academic level': ['High School', 'Undergraduate', 'Masters', 'PhD'],
    'opportunity type': [
      'Scholarships', 'Internships', 'Fellowships',
      'Research Programs', 'Exchange Programs', 'Global Summits',
    ],
    'type of opportunit': [
      'Scholarships', 'Internships', 'Fellowships',
      'Research Programs', 'Exchange Programs', 'Global Summits',
    ],
    'kind of opportunit': [
      'Scholarships', 'Internships', 'Fellowships',
      'Research Programs', 'Exchange Programs', 'Global Summits',
    ],
    'field of study': [
      'Computer Science', 'Engineering', 'Business',
      'Medicine', 'Arts', 'Other',
    ],
    'what field': [
      'Computer Science', 'Engineering', 'Business',
      'Medicine', 'Arts', 'Other',
    ],
    'which field': [
      'Computer Science', 'Engineering', 'Business',
      'Medicine', 'Arts', 'Other',
    ],
    'preferred country': [
      'USA', 'Europe', 'Canada', 'Asia', 'Global / No Preference',
    ],
    'preferred region': [
      'USA', 'Europe', 'Canada', 'Asia', 'Global / No Preference',
    ],
    'which region': [
      'USA', 'Europe', 'Canada', 'Asia', 'Global / No Preference',
    ],
    'which countr': [
      'USA', 'Europe', 'Canada', 'Asia', 'Global / No Preference',
    ],
    'prefer to study': [
      'USA', 'Europe', 'Canada', 'Asia', 'Global / No Preference',
    ],
  };

  List<String> _getQuickReplies() {
    if (_isLoading || _messages.isEmpty) return [];
    final last = _messages.last;
    if (last.role != roleAssistant) return [];

    final lower = last.content.toLowerCase();
    for (final entry in _quickReplyMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return [];
  }

  @override
  Component build(BuildContext context) {
    return .fragment([
      div(key: _messagesKey, classes: 'chat-messages', [
        for (final msg in _messages) MessageBubble(message: msg),
        if (_isLoading)
          div(classes: 'typing-indicator', [
            div(classes: 'typing-dots', [
              span([]),
              span([]),
              span([]),
            ]),
            .text('$appName is thinking...'),
          ]),
      ]),
      if (_getQuickReplies().isNotEmpty)
        div(classes: 'quick-replies', [
          for (final option in _getQuickReplies())
            button(
              classes: 'quick-reply-chip',
              onClick: () => _sendMessage(option),
              [.text(option)],
            ),
        ]),
      ChatInputBar(onSend: _sendMessage, isLoading: _isLoading),
    ]);
  }
}
