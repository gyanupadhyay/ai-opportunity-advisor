import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../services/speech_service.dart';

class ChatInputBar extends StatefulComponent {
  final void Function(String text) onSend;
  final bool isLoading;

  const ChatInputBar({
    required this.onSend,
    required this.isLoading,
    super.key,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _isRecording = false;
  String _currentInput = '';

  final SpeechService _speechService = SpeechService();
  final GlobalNodeKey<web.HTMLInputElement> _inputKey = GlobalNodeKey();

  void _handleSend() {
    final text = _currentInput.trim();
    if (text.isEmpty || component.isLoading) return;

    final inputEl = _inputKey.currentNode;
    if (inputEl != null) inputEl.value = '';
    _currentInput = '';

    component.onSend(text);
  }

  void _toggleMic() {
    if (!_speechService.isSupported || component.isLoading) return;

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
        _handleSend();
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
    return div(classes: 'chat-input-area', [
      input<String>(
        key: _inputKey,
        classes: 'chat-input',
        type: InputType.text,
        attributes: {
          'placeholder':
              _isRecording ? 'Listening...' : 'Type your answer...',
        },
        onInput: (value) {
          _currentInput = value;
        },
        events: {
          'keydown': (event) {
            final ke = event as web.KeyboardEvent;
            if (ke.key == 'Enter' && !component.isLoading) {
              _handleSend();
            }
          },
        },
      ),
      if (_speechService.isSupported)
        button(
          classes: 'mic-btn${_isRecording ? ' recording' : ''}',
          disabled: component.isLoading,
          onClick: _toggleMic,
          [.text(_isRecording ? '\u{23F9}' : '\u{1F3A4}')],
        ),
      button(
        classes: 'send-btn',
        disabled: component.isLoading,
        onClick: _handleSend,
        [.text('Send \u{27A4}')],
      ),
    ]);
  }
}
