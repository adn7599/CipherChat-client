import 'dart:io';

import 'package:cipher_chat/Screens/Messages/messages_main.dart';
import 'package:cipher_chat/Screens/User/splash.dart';
import 'package:cipher_chat/Screens/User/welcome.dart';
import 'package:cipher_chat/globalState/global_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  GlobalState _gState = GlobalState();
  Future<void>? loadStateFuture;

  Future<void> loadState() async {
    await _gState.loadState();
    await Future.delayed(const Duration(seconds: 1));
    if (_gState.user == null) {
      debugPrint('User not found');
    } else {
      debugPrint('User found');
      //connecting to the websocket
      try {
        await _gState.initMessageWebSocket();
      } on WebSocketException catch (e) {
        debugPrint('WebSocketException Exception message: ${e.message}');
        await _gState.clearOnlyUser();
        throw Exception('Websocket exception');
      } on SocketException catch (e) {
        debugPrint(
            'Socket Exception message (unable to connect): ${e.message}');
        _gState.launchReconnectIsolate();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadStateFuture = loadState();
  }

  @override
  void dispose() {
    _gState.closeMessageWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return _gState;
      },
      child: MaterialApp(
          title: 'Cipher Chat',
          theme: ThemeData(
            colorScheme: const ColorScheme(
                brightness: Brightness.light,
                primary: Colors.black,
                onPrimary: Colors.white,
                secondary: Colors.grey,
                onSecondary: Colors.white,
                error: Colors.red,
                onError: Colors.white,
                background: Colors.white,
                onBackground: Colors.black,
                surface: Colors.white,
                onSurface: Colors.black),
            textTheme: const TextTheme(
                displayLarge: TextStyle(
                  fontSize: 24,
                ),
                titleLarge: TextStyle(
                  fontSize: 24,
                ),
                bodyMedium: TextStyle(fontSize: 22),
                labelLarge: TextStyle(fontSize: 16)),
          ),
          home: FutureBuilder(
              future: loadStateFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_gState.user == null) {
                    return WelcomeScreen();
                  } else {
                    if (snapshot.hasError) {
                      //Websocket or some other error
                      return WelcomeScreen();
                    }
                    return MessagesMainScreen();
                  }
                } else {
                  return SplashScreen();
                }
              })),
    );
  }
}
