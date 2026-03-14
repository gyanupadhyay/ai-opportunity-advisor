import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../models/message.dart';
import '../services/api_service.dart';
import '../services/speech_service.dart';
import 'message_bubble.dart';

class ChatWidget extends StatefulComponent {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  String _currentInput = '';

  final SpeechService _speechService = SpeechService();
  final GlobalNodeKey<web.HTMLInputElement> _inputKey = GlobalNodeKey();
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
      final response = await ApiService.sendMessage('__start__');
      setState(() {
        _messages.add(
          ChatMessage(
            content: response.reply,
            role: 'assistant',
            opportunities: response.opportunities,
          ),
        );
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(
          ChatMessage(
            content:
                'Hi there! I\u{2019}m Pathora AI, your personal guide to '
                'discovering scholarships, internships, fellowships, and global '
                'opportunities.\n\n'
                'Let\u{2019}s start \u{2014} which country are you from?',
            role: 'assistant',
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
        container.scrollTop = container.scrollHeight.toDouble();
      }
    });
  }

  Future<void> _sendMessage([String? prefilled]) async {
    final text = prefilled ?? _currentInput.trim();
    if (text.isEmpty || _isLoading) return;

    final inputEl = _inputKey.currentNode;
    if (inputEl != null) inputEl.value = '';
    _currentInput = '';

    setState(() {
      _messages.add(ChatMessage(content: text, role: 'user'));
      _isLoading = true;
    });

    _scrollToBottom();

    final response = await ApiService.sendMessage(text);

    setState(() {
      _messages.add(
        ChatMessage(
          content: response.reply,
          role: 'assistant',
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
    if (last.role != 'assistant') return [];

    final lower = last.content.toLowerCase();
    for (final entry in _quickReplyMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return [];
  }

  void _toggleMic() {
    if (!_speechService.isSupported || _isLoading) return;

    if (_isRecording) {
      _speechService.stop();
      setState(() => _isRecording = false);
      return;
    }

    setState(() => _isRecording = true);

    _speechService.start(
      onResult: (transcript) {
        final inputEl = _inputKey.currentNode;
        if (inputEl != null) inputEl.value = transcript;
        _currentInput = transcript;
        _sendMessage();
      },
      onEnd: () {
        setState(() => _isRecording = false);
      },
      onError: (error) {
        setState(() => _isRecording = false);
      },
    );
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
            .text('Pathora AI is thinking...'),
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
      div(classes: 'chat-input-area', [
        input<String>(
          key: _inputKey,
          classes: 'chat-input',
          type: InputType.text,
          attributes: {
            'placeholder': _isRecording ? 'Listening...' : 'Type your answer...',
          },
          onInput: (value) {
            _currentInput = value;
          },
          events: {
            'keydown': (event) {
              final ke = event as web.KeyboardEvent;
              if (ke.key == 'Enter' && !_isLoading) {
                _sendMessage();
              }
            },
          },
        ),
        if (_speechService.isSupported)
          button(
            classes: 'mic-btn${_isRecording ? ' recording' : ''}',
            disabled: _isLoading,
            onClick: _toggleMic,
            [.text(_isRecording ? '\u{23F9}' : '\u{1F3A4}')],
          ),
        button(
          classes: 'send-btn',
          disabled: _isLoading,
          onClick: () => _sendMessage(),
          [.text('Send \u{27A4}')],
        ),
      ]),
    ]);
  }
}
