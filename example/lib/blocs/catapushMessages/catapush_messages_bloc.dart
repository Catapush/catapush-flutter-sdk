import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:catapush_flutter_sdk/catapush_flutter_sdk.dart';
import 'package:equatable/equatable.dart';

part 'catapush_messages_event.dart';
part 'catapush_messages_state.dart';

class CatapushMessagesBloc extends Bloc<CatapushMessagesEvent, CatapushMessagesState> {
  CatapushMessagesBloc() : super(const CatapushMessagesStateWithValue([]));

  @override
  Stream<CatapushMessagesState> mapEventToState(
    CatapushMessagesEvent event,
  ) async* {
    final allMessages = await Catapush.shared.allMessages();
    yield CatapushMessagesStateWithValue(allMessages);
  }
}
