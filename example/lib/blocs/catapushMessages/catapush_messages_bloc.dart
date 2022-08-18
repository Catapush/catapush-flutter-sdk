import 'package:catapush_flutter_sdk/catapush_flutter_sdk.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'catapush_messages_event.dart';
part 'catapush_messages_state.dart';

class CatapushMessagesBloc extends Bloc<CatapushMessagesEvent, CatapushMessagesState> {

  CatapushMessagesBloc() : super(const CatapushMessagesStateWithValue([])) {
    on<CatapushMessagesEventFetch>((event, emit) async {
      final allMessages = await Catapush.shared.allMessages();
      emit(CatapushMessagesStateWithValue(allMessages));
    });
  }

}
