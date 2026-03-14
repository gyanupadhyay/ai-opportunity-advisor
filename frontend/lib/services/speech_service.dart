import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Chrome/Edge/Safari expose [webkitSpeechRecognition] instead of the
/// standard [SpeechRecognition] constructor.  This extension type lets us
/// call `new webkitSpeechRecognition()` from Dart while reusing the same
/// typed interface that `package:web` provides.
@JS('webkitSpeechRecognition')
extension type _WebkitSpeechRecognition._(JSObject _) implements web.SpeechRecognition {
  external factory _WebkitSpeechRecognition();
}

/// Thin wrapper around the browser Web Speech API.
///
/// Handles the webkit vendor prefix transparently so callers don't need to
/// worry about which constructor to use.
class SpeechService {
  web.SpeechRecognition? _recognition;
  bool _listening = false;

  bool get isListening => _listening;

  /// Whether the current browser supports the Web Speech API at all.
  bool get isSupported =>
      globalContext['webkitSpeechRecognition'] != null || globalContext['SpeechRecognition'] != null;

  web.SpeechRecognition _create() {
    if (globalContext['webkitSpeechRecognition'] != null) {
      return _WebkitSpeechRecognition();
    }
    return web.SpeechRecognition();
  }

  /// Begin listening to the microphone.
  ///
  /// * [onResult] fires once with the final transcript.
  /// * [onEnd] fires when recognition stops (automatically after one phrase
  ///   because `continuous` is `false`).
  /// * [onError] fires if anything goes wrong (permission denied, no speech
  ///   detected, etc.).
  void start({
    required void Function(String transcript) onResult,
    required void Function() onEnd,
    void Function(String error)? onError,
  }) {
    if (_listening || !isSupported) return;

    final rec = _create();
    _recognition = rec;

    rec.continuous = false;
    rec.interimResults = false;
    rec.lang = 'en-US';

    rec.addEventListener(
      'result',
      ((web.Event e) {
        try {
          final event = e as web.SpeechRecognitionEvent;
          final results = event.results;
          if (results.length > 0) {
            final transcript = results.item(0).item(0).transcript;
            if (transcript.isNotEmpty) {
              onResult(transcript);
            }
          }
        } catch (_) {
          onError?.call('Failed to process speech');
        }
      }).toJS,
    );

    rec.addEventListener(
      'error',
      ((web.Event e) {
        _listening = false;
        onError?.call('Speech recognition error');
      }).toJS,
    );

    rec.addEventListener(
      'end',
      ((web.Event e) {
        _listening = false;
        onEnd();
      }).toJS,
    );

    rec.start();
    _listening = true;
  }

  /// Stop an in-progress recognition session.
  void stop() {
    _recognition?.stop();
    _listening = false;
  }
}
