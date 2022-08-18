part of 'catapush_messages_bloc.dart';

abstract class CatapushMessagesState extends Equatable {
  const CatapushMessagesState();
}

@immutable
class CatapushMessagesStateWithValue extends CatapushMessagesState {
  final List<CatapushMessage> messages;

  const CatapushMessagesStateWithValue(this.messages);

  @override
  List<Object> get props => [messages];
}
