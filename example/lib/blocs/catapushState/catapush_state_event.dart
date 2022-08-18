part of 'catapush_state_bloc.dart';

@immutable
class CatapushStateEvent extends Equatable {
  final CatapushState state;

  const CatapushStateEvent(this.state);

  @override
  List<Object?> get props => [state];
}
