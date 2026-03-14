import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

@JS('pathoraSignInWithGoogle')
external JSPromise<JSBoolean?> _jsSignInWithGoogle();

@JS('pathoraSignOut')
external JSPromise<JSAny?> _jsSignOut();

class AuthUser {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;

  const AuthUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
  });
}

class AuthService {
  static const _keyUid = 'pathora_uid';
  static const _keyToken = 'pathora_id_token';
  static const _keyName = 'pathora_user_name';
  static const _keyEmail = 'pathora_user_email';
  static const _keyPhoto = 'pathora_user_photo';

  static bool get isLoggedIn {
    final uid = web.window.localStorage.getItem(_keyUid);
    return uid != null && uid.isNotEmpty;
  }

  static String? get uid => web.window.localStorage.getItem(_keyUid);

  static String? get idToken => web.window.localStorage.getItem(_keyToken);

  static AuthUser? get currentUser {
    final uid = web.window.localStorage.getItem(_keyUid);
    if (uid == null || uid.isEmpty) return null;
    return AuthUser(
      uid: uid,
      name: web.window.localStorage.getItem(_keyName) ?? '',
      email: web.window.localStorage.getItem(_keyEmail) ?? '',
      photoUrl: web.window.localStorage.getItem(_keyPhoto) ?? '',
    );
  }

  static Future<bool> signInWithGoogle() async {
    try {
      final result = await _jsSignInWithGoogle().toDart;
      return result?.toDart ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await _jsSignOut().toDart;
    } catch (_) {
      // JS cleanup handles localStorage
    }
  }

  static void onAuthChanged(void Function(bool loggedIn) callback) {
    web.window.addEventListener(
      'pathora-auth-changed',
      ((web.Event e) {
        final ce = e as web.CustomEvent;
        final detail = ce.detail;
        if (detail != null) {
          final map = detail as JSObject;
          final loggedIn = (map['loggedIn'] as JSBoolean?)?.toDart ?? false;
          callback(loggedIn);
        }
      }).toJS,
    );
  }
}
