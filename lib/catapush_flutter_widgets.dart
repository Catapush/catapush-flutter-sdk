import 'dart:io';

import 'package:catapush_flutter_sdk/catapush_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CatapushMessageWidget extends StatelessWidget {

  static const oneDay = Duration(hours: 24);
  static final formatHour = DateFormat('HH:mm');
  static final formatDay = DateFormat('dd MMM');

  final CatapushMessage message;
  final double screenWidth;
  final bool isLightTheme;
  final TextTheme textTheme;
  final Color backgroundColor;
  final Color backgroundInverseColor;

  const CatapushMessageWidget({
    Key? key,
    required this.message,
    required this.screenWidth,
    required this.isLightTheme,
    required this.textTheme,
    required this.backgroundColor,
    required this.backgroundInverseColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.state == CatapushMessageState.SENT
        || message.state == CatapushMessageState.SENT_CONFIRMED) {
      return _buildSentMessage(context);
    } else {
      return _buildReceivedMessage(context);
    }
  }

  Widget _buildReceivedMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0,),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isLightTheme ? Colors.grey : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                  bottomLeft: Radius.zero,
                  bottomRight: Radius.circular(8.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.body ?? '',
                    style: textTheme.bodyText1,
                  ),
                  Text(
                    _formatMessageDate() + _confirmedCheck(),
                    style: textTheme.caption,
                  ),
                  if (message.hasAttachment) _buildImageBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0,),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.75,
            ),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isLightTheme ? backgroundColor : backgroundInverseColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                  bottomRight: Radius.zero,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.body ?? '',
                    style: textTheme.bodyText1,
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    _formatMessageDate() + _confirmedCheck(),
                    style: textTheme.caption,
                  ),
                  if (message.hasAttachment) _buildImageBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBox() {
    return FutureBuilder<CatapushFile>(
      future: Catapush.shared.getAttachmentUrlForMessage(message), // async work
      builder: (BuildContext context, AsyncSnapshot<CatapushFile> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(textTheme.caption!.color!),
          );
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: textTheme.bodyText1,
          );
        } else {
          final url = snapshot.data!.url;
          if (url.startsWith('https://') || url.startsWith('http://')) {
            return Image.network(url);
          } else {
            return Image.file(File(snapshot.data!.url));
          }
        }
      },
    );
  }

  String _formatMessageDate() {
    if (message.sentTime == null) {
      return '';
    }
    if (message.sentTime!.difference(DateTime.now()) < oneDay) {
      return formatHour.format(message.sentTime!);
    } else {
      return formatDay.format(message.sentTime!);
    }
  }

  String _confirmedCheck() {
    if (message.state == CatapushMessageState.RECEIVED_CONFIRMED
        || message.state == CatapushMessageState.OPENED
        || message.state == CatapushMessageState.OPENED_CONFIRMED
        || message.state == CatapushMessageState.SENT_CONFIRMED) {
      return ' ✓';
    } else {
      return '';
    }
  }

}