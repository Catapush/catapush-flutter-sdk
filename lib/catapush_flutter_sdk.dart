library catapush_flutter_sdk;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:catapush_flutter_sdk/catapush_flutter_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/subjects.dart';

export 'catapush_flutter_models.dart';
export 'catapush_flutter_widgets.dart';

class Catapush {
  static Catapush shared = Catapush();

  final MethodChannel _channel = const MethodChannel('Catapush');

  final _receivedMessageQueueSubject =
      ReplaySubject<CatapushMessage>(maxSize: 100);
  StreamSubscription? _receivedMessageQueueSubscription;
  final _sentMessageQueueSubject = ReplaySubject<CatapushMessage>(maxSize: 100);
  StreamSubscription? _sentMessageQueueSubscription;
  final _notificationTappedQueueSubject =
      ReplaySubject<CatapushMessage>(maxSize: 100);
  StreamSubscription? _notificationTappedQueueSubscription;
  final _stateSubject = BehaviorSubject<CatapushState>();
  StreamSubscription? _stateSubscription;
  final _errorQueueSubject = ReplaySubject<CatapushError>(maxSize: 100);
  StreamSubscription? _errorQueueSubscription;

  CatapushMessageDelegate? _catapushMessageDelegate;
  CatapushStateDelegate? _catapushStateDelegate;

  Catapush() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  /// Initializes the native Catapush SDK.<br />
  /// Wait for the Future to complete before invoking any other method of this
  /// plugin.
  Future<bool> init({iOSSettings? ios, AndroidSettings? android}) {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#init', {
      'ios': ios?.mapRepresentation(),
      'android': android?.mapRepresentation(),
    }).then((response) {
      return response!['result']! as bool;
    });
  }

  /// Sets the user credentials.<br />
  /// Provide the identifier and password that you have created with the
  /// Catapush dashboard or with the Catapush APIs.<br />
  /// You have to invoke this method at least once before starting the SDK.
  Future<bool> setUser(String identifier, String password) {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#setUser', {
      'identifier': identifier,
      'password': password,
    }).then((response) {
      return response!['result']! as bool;
    });
  }

  /// Starts the Catapush native SDK.
  Future<bool> start() {
    return _channel
        .invokeMethod<Map<Object?, Object?>>('Catapush#start')
        .then((response) {
      return response!['result']! as bool;
    });
  }

  /// Stops the Catapush native SDK.
  Future<bool> stop() {
    return _channel
        .invokeMethod<Map<Object?, Object?>>('Catapush#stop')
        .then((response) {
      return response!['result']! as bool;
    });
  }

  /// Sends a message to the Catapush backend for delivery.
  Future<bool> sendMessage(CatapushSendMessage message) {
    return _channel
        .invokeMethod<Map<Object?, Object?>>('Catapush#sendMessage', {
      'message': message.mapRepresentation(),
    }).then((response) {
      return response!['result']! as bool;
    });
  }

  /// Lists all messages received by the currently logged user.
  Future<List<CatapushMessage>> allMessages() {
    return _channel
        .invokeMethod<Map<Object?, Object?>>('Catapush#getAllMessages')
        .then((response) {
      final messages = (response!['result']! as List<Object?>)
          .map((e) => CatapushMessage.fromMap(
              LinkedHashMap<String, dynamic>.from(e! as Map)))
          .toList(growable: false);

      if (messages.isEmpty) {
        debugPrint(
            'Catapush Flutter SDK - Catapush#getAllMessages no messages');
      } else {
        debugPrint(
            'Catapush Flutter SDK - Catapush#getAllMessages most recent message: ${messages.first}');
      }

      return messages;
    });
  }

  /// Enables or disables the SDK logging.
  Future<bool> enableLog(bool enabled) {
    return _channel.invokeMethod<Map<Object?, Object?>>('Catapush#enableLog', {
      'enableLog': enabled,
    }).then((response) {
      return response!['result']! as bool;
    });
  }

  /// Disconnects the current user.
  Future<bool> logout() {
    return _channel
        .invokeMethod<Map<Object?, Object?>>('Catapush#logout')
        .then((response) {
      return response!['result']! as bool;
    });
  }

  /// Confirms that a message has been read by the user.
  Future<bool> sendMessageReadNotificationWithId(String id) {
    return _channel.invokeMethod<Map<Object?, Object?>>(
        'Catapush#sendMessageReadNotificationWithId', {
      'id': id,
    }).then((response) {
      return response!['result']! as bool;
    });
  }

  /// Sets the delegate that will be informed of all messaging events of the
  /// native SDK.
  void setCatapushMessageDelegate(CatapushMessageDelegate delegate) {
    _catapushMessageDelegate = delegate;

    _receivedMessageQueueSubscription?.cancel();
    _receivedMessageQueueSubscription = _receivedMessageQueueSubject
        .listen(_catapushMessageDelegate?.catapushMessageReceived);

    _sentMessageQueueSubscription?.cancel();
    _sentMessageQueueSubscription = _sentMessageQueueSubject
        .listen(_catapushMessageDelegate?.catapushMessageSent);

    _notificationTappedQueueSubscription?.cancel();
    _notificationTappedQueueSubscription = _notificationTappedQueueSubject
        .listen(_catapushMessageDelegate?.catapushNotificationTapped);
  }

  /// Sets the delegate that will be informed of all state change events of the
  /// native SDK.
  void setCatapushStateDelegate(CatapushStateDelegate delegate) {
    _catapushStateDelegate = delegate;

    _stateSubscription?.cancel();
    _stateSubscription =
        _stateSubject.listen(_catapushStateDelegate?.catapushStateChanged);

    _errorQueueSubscription?.cancel();
    _errorQueueSubscription =
        _errorQueueSubject.listen(_catapushStateDelegate?.catapushHandleError);
  }

  /// Obtains the file attached to the message.
  Future<CatapushFile> getAttachmentUrlForMessage(
      CatapushMessage message) async {
    if (!message.hasAttachment) {
      return Future.error('Message has no attachment');
    }
    return _channel.invokeMethod<Map<Object?, Object?>>(
        'Catapush#getAttachmentUrlForMessage', {
      'id': message.id,
    }).then((response) {
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
      return _channel.invokeMethod('Catapush#resumeNotifications', null);
    }
  }

  /// <b>Android only</b><br />
  /// Pause notifications until next Catapush start or until [Catapush.resumeNotifications()]
  Future<void> pauseNotifications() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('Catapush#pauseNotifications', null);
    }
  }

  /// <b>Android only</b><br />
  /// Enable notifications, this status will be persisted across Catapush starts
  Future<void> enableNotifications() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('Catapush#enableNotifications', null);
    }
  }

  /// <b>Android only</b><br />
  /// Disable notifications, this status will be persisted across Catapush starts
  Future<void> disableNotifications() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('Catapush#disableNotifications', null);
    }
  }

  // Private function that gets called by ObjC/Java
  Future<void> _handleMethod(MethodCall call) async {
    if (call.method == 'Catapush#catapushMessageReceived') {
      final args = call.arguments as Map<Object?, Object?>;
      final message = CatapushMessage.fromMap(
          (args['message']! as Map<dynamic, dynamic>).cast<String, dynamic>());
      if (_catapushMessageDelegate != null) {
        _catapushMessageDelegate?.catapushMessageReceived(message);
      } else {
        _receivedMessageQueueSubject.add(message);
      }
    } else if (call.method == 'Catapush#catapushMessageSent') {
      final args = call.arguments as Map<Object?, Object?>;
      final message = CatapushMessage.fromMap(
          (args['message']! as Map<dynamic, dynamic>).cast<String, dynamic>());
      if (_catapushMessageDelegate != null) {
        _catapushMessageDelegate?.catapushMessageSent(message);
      } else {
        _sentMessageQueueSubject.add(message);
      }
    } else if (call.method == 'Catapush#catapushStateChanged') {
      CatapushState catapushState;
      final args = call.arguments as Map<Object?, Object?>;
      switch ((args['status']! as String).toUpperCase()) {
        case 'DISCONNECTED':
          catapushState = CatapushState.DISCONNECTED;
          break;
        case 'CONNECTED':
          catapushState = CatapushState.CONNECTED;
          break;
        default:
          catapushState = CatapushState.CONNECTING;
          break;
      }
      _stateSubject.add(catapushState);
    } else if (call.method == 'Catapush#catapushNotificationTapped') {
      final args = call.arguments as Map<Object?, Object?>;
      final message = CatapushMessage.fromMap(
          (args['message']! as Map<dynamic, dynamic>).cast<String, dynamic>());
      if (_catapushMessageDelegate != null) {
        _catapushMessageDelegate?.catapushNotificationTapped(message);
      } else {
        _notificationTappedQueueSubject.add(message);
      }
    } else if (call.method == 'Catapush#catapushHandleError') {
      final args = call.arguments as Map<Object?, Object?>;
      final error = CatapushError(
        args['event']! as String,
        args['code']! as int,
      );
      if (_catapushStateDelegate != null) {
        _catapushStateDelegate?.catapushHandleError(error);
      } else {
        _errorQueueSubject.add(error);
      }
    }
  }
}
