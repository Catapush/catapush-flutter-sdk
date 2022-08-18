part of 'catapush_messages_bloc.dart';

abstract class CatapushMessagesEvent extends Equatable {
  const CatapushMessagesEvent();
}

@immutable
class CatapushMessagesEventFetch extends CatapushMessagesEvent{
  @override
  List<Object?> get props => [];
}
