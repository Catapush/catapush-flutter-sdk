import 'package:catapush_flutter_sdk/catapush_flutter_sdk.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'catapush_state_event.dart';
part 'catapush_state_state.dart';

class CatapushStateBloc extends Bloc<CatapushStateEvent, CatapushStateState> {

  CatapushStateBloc() : super(const CatapushStateState(CatapushState.DISCONNECTED)) {
    on<CatapushStateEvent>((event, emit) async {
      emit(CatapushStateState(event.state));
    });
  }

}
