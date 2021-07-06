part of 'catapush_state_bloc.dart';

class CatapushStateState extends Equatable {

  final CatapushState state;

  const CatapushStateState(this.state);

  @override
  List<Object> get props => [state];
}