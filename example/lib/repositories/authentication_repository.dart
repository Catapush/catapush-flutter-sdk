import 'dart:async';

import 'package:catapush_flutter_sdk_example/models/user.dart';
import 'package:catapush_flutter_sdk_example/repositories/user_repository.dart';

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticationRepository {
  AuthenticationRepository(this._userRepository);

  final UserRepository _userRepository;
  final _controller = StreamController<AuthenticationStatus>();

  Stream<AuthenticationStatus> get status async* {
    final user = await _tryGetUser();
    if (user != null){
      yield AuthenticationStatus.authenticated;
    }else {
      yield AuthenticationStatus.unauthenticated;
    }
    yield* _controller.stream;
  }

  Future<void> logIn({
    required String identifier,
    required String password,
  }) async {
    await _userRepository.setUser(User(identifier: identifier, password: password));
    await Future.delayed(
      const Duration(milliseconds: 300),
          () => _controller.add(AuthenticationStatus.authenticated),
    );
  }

  Future<void> logOut() async {
    await _userRepository.logout();
    _controller.add(AuthenticationStatus.unauthenticated);
  }

  void dispose() => _controller.close();

  Future<User?> _tryGetUser() async {
    try {
      final user = await _userRepository.getUser();
      return user;
    } on Exception {
      return null;
    }
  }
}