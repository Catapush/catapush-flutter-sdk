library catapush_flutter_sdk;
import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:catapush_flutter_sdk/catapush_flutter_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

export 'catapush_flutter_models.dart';
export 'catapush_flutter_widgets.dart';


class Catapush {
  static Catapush shared = Catapush();

  final MethodChannel _channel = const MethodChannel('Catapush');

  CatapushMessageDelegate? _catapushMessageDelegate;
  CatapushStateDelegate? _catapushStateDelegate;

  Catapush() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  Future<bool> init({iOSSettings? ios, AndroidSettings? android}) {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#init', {
      'ios': ios?.mapRepresentation(),
      'android': android?.mapRepresentation(),
    })
        .then((response) {
      return response!['result']! as bool;
    });
  }

  Future<bool> setUser(String identifier, String password) {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#setUser', {
      'identifier': identifier,
      'password': password,
    })
        .then((response) {
      return response!['result']! as bool;
    });
  }

  Future<bool> start() {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#start')
        .then((response) {
      return response!['result']! as bool;
    });
  }

  Future<bool> sendMessage(CatapushSendMessage message) {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#sendMessage', {
      'message': message.mapRepresentation(),
    })
        .then((response) {
      return response!['result']! as bool;
    });
  }

  Future<List<CatapushMessage>> allMessages() {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#getAllMessages')
        .then((response) {
      final messages = (response!['result']! as List<Object?>)
          .map((e) => CatapushMessage.fromMap(LinkedHashMap<String, dynamic>.from(e! as Map)))
          .toList(growable: false);

      if (messages.isEmpty) {
        debugPrint('Catapush Flutter SDK - Catapush#getAllMessages no messages');
      } else {
        debugPrint('Catapush Flutter SDK - Catapush#getAllMessages most recent message: ${messages.first}');
      }

      return messages;
    });
  }

  Future<bool> enableLog(bool enabled) {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#enableLog', {
      'enableLog': enabled,
    })
        .then((response) {
      return response!['result']! as bool;
    });
  }

  Future<bool> logout() {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#logout')
        .then((response) {
      return response!['result']! as bool;
    });
  }

  Future<bool> sendMessageReadNotificationWithId(String id) {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#sendMessageReadNotificationWithId', {
      'id': id,
    })
        .then((response) {
      return response!['result']! as bool;
    });
  }

  void setCatapushMessageDelegate(CatapushMessageDelegate delegate) {
    _catapushMessageDelegate = delegate;
  }

  void setCatapushStateDelegate(CatapushStateDelegate delegate) {
    _catapushStateDelegate = delegate;
  }

  Future<CatapushFile> getAttachmentUrlForMessage(CatapushMessage message) async {
    if (!message.hasAttachment) {
      return Future.error('Message has no attachment');
    }
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#getAttachmentUrlForMessage', {
      'id': message.id,
    })
        .then((response) {
      if ((response?['url'] as String?)?.isNotEmpty ?? false) {
        return CatapushFile(
          response!['mimeType'] as String? ?? '',
          response['url']! as String,
        );
      }
      return Future.error("Can't retrieve attachment");
    });
  }

  /// <b>Android only</b><br />
  /// Resume notifications until next Catapush start or until [Catapush.pauseNotifications()]
  Future<void> resumeNotifications() async {
    if (Platform.isAndroid) {
      return _channel
          .invokeMethod('Catapush#resumeNotifications', null);
    }
  }

  /// <b>Android only</b><br />
  /// Pause notifications until next Catapush start or until [Catapush.resumeNotifications()]
  Future<void> pauseNotifications() async {
    if (Platform.isAndroid) {
      return _channel
          .invokeMethod('Catapush#pauseNotifications', null);
    }
  }

  /// <b>Android only</b><br />
  /// Enable notifications, this status will be persisted across Catapush starts
  Future<void> enableNotifications() async {
    if (Platform.isAndroid) {
      return _channel
          .invokeMethod('Catapush#enableNotifications', null);
    }
  }

  /// <b>Android only</b><br />
  /// Disable notifications, this status will be persisted across Catapush starts
  Future<void> disableNotifications() async {
    if (Platform.isAndroid) {
      return _channel
          .invokeMethod('Catapush#disableNotifications', null);
    }
  }

  // Private function that gets called by ObjC/Java
  Future<void> _handleMethod(MethodCall call) async {
    debugPrint('Catapush Flutter SDK - native layer invoked ${call.method}');

    if (call.method == 'Catapush#catapushMessageReceived'
        && _catapushMessageDelegate != null) {
      final args = call.arguments as Map<Object?, Object?>;
      final result = CatapushMessage
          .fromMap((args['message']! as Map<dynamic, dynamic>)
          .cast<String, dynamic>());
      _catapushMessageDelegate?.catapushMessageReceived(result);

    } else if (call.method == 'Catapush#catapushMessageSent'
        && _catapushMessageDelegate != null) {
      final args = call.arguments as Map<Object?, Object?>;
      final result = CatapushMessage
          .fromMap((args['message']! as Map<dynamic, dynamic>)
          .cast<String, dynamic>());
      _catapushMessageDelegate?.catapushMessageSent(result);

    } else if (call.method == 'Catapush#catapushStateChanged'
        && _catapushStateDelegate != null) {
      CatapushState status;
      final args = call.arguments as Map<Object?, Object?>;
      switch((args['status']! as String).toUpperCase()){
        case 'DISCONNECTED':
          status = CatapushState.DISCONNECTED;
          break;
        case 'CONNECTED':
          status = CatapushState.CONNECTED;
          break;
        default:
          status = CatapushState.CONNECTING;
          break;
      }
      _catapushStateDelegate?.catapushStateChanged(status);

    } else if (call.method == 'Catapush#catapushHandleError'
        && _catapushStateDelegate != null) {
      final args = call.arguments as Map<Object?, Object?>;
      _catapushStateDelegate?.catapushHandleError(CatapushError(
        args['event']! as String,
        args['code']! as int,
      ));
    }
  }

}
