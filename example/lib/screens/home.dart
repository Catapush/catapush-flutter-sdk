import 'dart:io';

import 'package:catapush_flutter_sdk/catapush_flutter_sdk.dart';
import 'package:catapush_flutter_sdk_example/blocs/authentication/authentication_bloc.dart';
import 'package:catapush_flutter_sdk_example/blocs/catapushMessages/catapush_messages_bloc.dart';
import 'package:catapush_flutter_sdk_example/blocs/catapushState/catapush_state_bloc.dart';
import 'package:catapush_flutter_sdk_example/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({Key? key}) : super(key: key);

  static Route route() {
    return MaterialPageRoute<void>(builder: (_) => const HomeScreen());
  }

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  CatapushFile? _attachment;

  final _messageController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Catapush.shared.pauseNotifications();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      BlocProvider.of<CatapushMessagesBloc>(context).add(CatapushMessagesEventFetch());
      Catapush.shared.pauseNotifications();
    } else if (state == AppLifecycleState.paused) {
      Catapush.shared.resumeNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayWidth = MediaQuery.of(context).size.width;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final textThemeInverse = isLightTheme
        ? darkThemeData.textTheme : lightThemeData.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catapush Flutter Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Catapush.shared.logout();
              context.read<AuthenticationBloc>().add(AuthenticationLogoutRequested());
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Connection status banner
            BlocBuilder<CatapushStateBloc, CatapushStateState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.all(16.0,),
                  color: getColorForCatapushState(state.state),
                  child: Center(
                    child: Text(
                      state.state.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),

            // Message list
            Expanded(
              child: BlocBuilder<CatapushMessagesBloc, CatapushMessagesState>(
                builder: (context, state) => Scrollbar(
                  isAlwaysShown: true,
                  child: ListView.builder(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: (state as CatapushMessagesStateWithValue?)?.messages.length ?? 0,
                    itemBuilder: (context, index) {
                      final message = (state as CatapushMessagesStateWithValue?)!.messages[index];
                      if (message.state == CatapushMessageState.RECEIVED_CONFIRMED) {
                        // Send read/opened notification to the Catapush server
                        Catapush.shared.sendMessageReadNotificationWithId(message.id);
                      }
                      return CatapushMessageWidget(
                        message: message,
                        isLightTheme: isLightTheme,
                        screenWidth: displayWidth,
                        textTheme: textThemeInverse,
                        backgroundColor: primary,
                        backgroundInverseColor: primary.shade200,
                      );
                    },
                  ),
                ),
              ),
            ),

            // Send message row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0,),
              child: Row(
                children: [
                  IconButton(
                    icon: _attachment != null ? Image.file(File(_attachment!.url)) : const Icon(Icons.attach_file),
                    color: _attachment != null ? Theme.of(context).colorScheme.secondary : null,
                    tooltip: 'Send attachment',
                    onPressed: () async {
                      if (Platform.isAndroid) {
                        final status = await Permission.storage.status;
                        if (status.isPermanentlyDenied) {
                          return;
                        }
                        if (status.isDenied) {
                          final newStatus = await Permission.storage.request();
                          if (!newStatus.isGranted) {
                            return;
                          }
                        }
                      }
                      try {
                        final pickedFile = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          setState(() => _attachment = CatapushFile(
                            lookupMimeType(pickedFile.path) ?? '',
                            pickedFile.path,
                          ));
                        }
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        isDense: true,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: 'Send a message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0,),
                  ElevatedButton(
                    child: const Text('SEND'),
                    onPressed: () async {
                      await Catapush.shared.sendMessage(CatapushSendMessage(
                        text: _messageController.text,
                        file: _attachment,
                      ));
                      setState(() {
                        _attachment = null;
                      });
                      _messageController.clear();
                      BlocProvider.of<CatapushMessagesBloc>(context).add(CatapushMessagesEventFetch());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Catapush.shared.resumeNotifications();
    WidgetsBinding.instance?.removeObserver(this);
    _messageController.dispose();
    super.dispose();
  }

  Color getColorForCatapushState(CatapushState state) {
    switch (state){
      case CatapushState.DISCONNECTED:
        return Colors.red;
      case CatapushState.CONNECTING:
        return Colors.yellow;
      case CatapushState.CONNECTED:
        return Colors.green;
    }
  }

}