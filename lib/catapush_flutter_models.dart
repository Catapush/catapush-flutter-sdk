// ignore_for_file: constant_identifier_names

// ignore: camel_case_types
class iOSSettings {
  String appId;

  iOSSettings(this.appId);

  Map<String, dynamic> mapRepresentation() {
    final json = <String, dynamic>{'appId': appId};
    return json;
  }
}

class AndroidSettings {
  Map<String, dynamic> mapRepresentation() {
    final json = <String, dynamic>{};
    return json;
  }
}

enum CatapushState { DISCONNECTED, CONNECTING, CONNECTED }

class CatapushError {
  String event;
  int code;

  CatapushError(this.event, this.code);

  @override
  String toString() {
    return 'CatapushError{event: $event, code: $code}';
  }
}

abstract class CatapushStateDelegate {
  void catapushStateChanged(CatapushState state);
  void catapushHandleError(CatapushError error);
}

class CatapushFile {
  String mimeType;
  String url;
  //Future<ByteData> previewData;

  CatapushFile(
    this.mimeType,
    this.url,
    //this.previewData
  );

  Map<String, dynamic> mapRepresentation() {
    return <String, dynamic>{'mimeType': mimeType, 'url': url};
  }

  @override
  String toString() {
    return 'CatapushFile{mimeType: $mimeType, url: $url}';
  }
}

enum CatapushMessageState {
  RECEIVED,
  RECEIVED_CONFIRMED,
  OPENED,
  OPENED_CONFIRMED,
  NOT_SENT,
  SENT,
  SENT_CONFIRMED,
}

class CatapushMessage {
  String id;
  String sender;
  String? body;
  String? subject; // non esposto su iOS ma presente in core data
  String? previewText; // no iOS
  bool hasAttachment;
  String? channel;
  String? replyToId; // originalMessageId
  Map<String, dynamic>?
      optionalData; //verificare se le API limitano a 1 livello chiave valore String:String
  DateTime? receivedTime; // no iOS
  DateTime?
      readTime; // iOS lo gestisce in una tabella diversa e quindi valutare la join
  DateTime? sentTime;
  CatapushMessageState state;

  CatapushMessage({
    required this.id,
    required this.sender,
    this.body,
    this.subject,
    this.previewText,
    required this.hasAttachment,
    this.channel,
    this.replyToId,
    this.optionalData,
    this.receivedTime,
    this.readTime,
    this.sentTime,
    required this.state,
  });

  factory CatapushMessage.fromMap(Map<String, dynamic> json) => CatapushMessage(
        id: json['messageId'] as String,
        sender: json['sender'] as String,
        body: json['body'] as String?,
        channel: json['channel'] as String?,
        optionalData: json['optionalData'] != null
            ? (json['optionalData'] as Map<dynamic, dynamic>)
                .cast<String, dynamic>()
            : null,
        state: CatapushMessageState.values.firstWhere((e) {
          return e.toString() ==
              'CatapushMessageState.${json['state'] as String}';
        }),
        sentTime: DateTime.tryParse(json['sentTime'] as String? ?? ''),
        hasAttachment: json['hasAttachment'] as bool,
      );

  @override
  String toString() {
    return 'CatapushMessage{id: $id, sender: $sender, body: $body, subject: $subject, previewText: $previewText, hasAttachment: $hasAttachment, channel: $channel, replyToId: $replyToId, optionalData: $optionalData, receivedTime: $receivedTime, readTime: $readTime, sentTime: $sentTime, state: $state}';
  }
}

class CatapushSendMessage {
  final String? text;
  final String? channel;
  final String? replyTo;
  final CatapushFile? file;

  CatapushSendMessage({this.text, this.channel, this.replyTo, this.file});

  Map<String, dynamic> mapRepresentation() {
    final json = <String, dynamic>{
      'text': text,
      'channel': channel,
      'replyTo': replyTo,
      'file': file?.mapRepresentation()
    };
    return json;
  }
}

abstract class CatapushMessageDelegate {
  void catapushMessageReceived(CatapushMessage message);
  void catapushMessageSent(CatapushMessage message);
  void catapushNotificationTapped(CatapushMessage message);
}
