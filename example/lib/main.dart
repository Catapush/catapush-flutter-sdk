import 'dart:async';

import 'package:catapush_flutter_sdk/catapush_flutter_sdk.dart';
import 'package:catapush_flutter_sdk_example/blocs/authentication/authentication_bloc.dart';
import 'package:catapush_flutter_sdk_example/blocs/catapushMessages/catapush_messages_bloc.dart';
import 'package:catapush_flutter_sdk_example/blocs/catapushState/catapush_state_bloc.dart';
import 'package:catapush_flutter_sdk_example/repositories/authentication_repository.dart';
import 'package:catapush_flutter_sdk_example/repositories/user_repository.dart';
import 'package:catapush_flutter_sdk_example/screens/home.dart';
import 'package:catapush_flutter_sdk_example/screens/login.dart';
import 'package:catapush_flutter_sdk_example/screens/splash.dart';
import 'package:catapush_flutter_sdk_example/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final userRepository = UserRepository();
  runApp(App(
    authenticationRepository: AuthenticationRepository(userRepository),
    userRepository: userRepository,
  ));
}

class CMDelegate extends CatapushMessageDelegate{

  final CatapushMessagesBloc catapushMessagesBloc;

  CMDelegate(this.catapushMessagesBloc);

  @override
  void catapushMessageReceived(CatapushMessage message) {
    debugPrint('RECEIVED ${message.id}');
    catapushMessagesBloc.add(CatapushMessagesEventFetch());
  }

  @override
  void catapushMessageSent(CatapushMessage message) {
    debugPrint('SENT ${message.id}');
    catapushMessagesBloc.add(CatapushMessagesEventFetch());
  }

  @override
  void catapushNotificationTapped(CatapushMessage message) {
    debugPrint('NOTIFICATION TAPPED ${message.id}');
  }

}

class CSDelegate extends CatapushStateDelegate{

  final CatapushStateBloc catapushStateBloc;

  CSDelegate(this.catapushStateBloc);

  @override
  void catapushHandleError(CatapushError error) {
    debugPrint(error.toString());
  }

  @override
  void catapushStateChanged(CatapushState state) {
    catapushStateBloc.add(CatapushStateEvent(state));
  }

}

class App extends StatefulWidget {
  const App({
    super.key,
    required this.authenticationRepository,
    required this.userRepository,
  });

  final AuthenticationRepository authenticationRepository;
  final UserRepository userRepository;

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: widget.authenticationRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => CatapushStateBloc(),
          ),
          BlocProvider(
            create: (_) => CatapushMessagesBloc(),
          ),
          BlocProvider(
            create: (_) => AuthenticationBloc(
              authenticationRepository: widget.authenticationRepository,
              userRepository: widget.userRepository,
            ),
          )
        ],
        child: const AppView(),
      ),
    );
  }
}


class AppView extends StatefulWidget{
  const AppView({super.key});

  @override
  AppViewState createState() => AppViewState();
}

class AppViewState extends State<AppView> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => _navigatorKey.currentState!;

  @override
  void initState() {
    super.initState();
    initCatapush();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initCatapush() async {
    Catapush.shared.enableLog(!kReleaseMode);

    Catapush.shared.setCatapushMessageDelegate(
        CMDelegate(BlocProvider.of<CatapushMessagesBloc>(context)));
    Catapush.shared.setCatapushStateDelegate(
        CSDelegate(BlocProvider.of<CatapushStateBloc>(context)));

    final init = await Catapush.shared.init(
      ios: iOSSettings('YOUR CATAPUSH APP KEY'),
    );
    debugPrint('Init: $init');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      themeMode: ThemeMode.system,
      theme: lightThemeData,
      darkTheme: darkThemeData,
      onGenerateRoute: (_) => SplashScreen.route(),
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            switch (state.status) {
              case AuthenticationStatus.authenticated:
                BlocProvider.of<CatapushMessagesBloc>(context).add(CatapushMessagesEventFetch());
                Catapush.shared.setUser(state.user.identifier, state.user.password);
                Catapush.shared.start();
                _navigator.pushAndRemoveUntil<void>(
                  HomeScreen.route(),
                      (route) => false,
                );
                break;
              case AuthenticationStatus.unauthenticated:
                _navigator.pushAndRemoveUntil<void>(
                  LoginScreen.route(),
                      (route) => false,
                );
                break;
              default:
                break;
            }
          },
          child: child,
        );
      },
    );
  }
}