import 'package:cipher_chat/Screens/Messages/messages_list.dart';
import 'package:cipher_chat/Screens/Messages/messages_main.dart';
import 'package:cipher_chat/Screens/Messages/messages_new.dart';
import 'package:cipher_chat/Screens/User/login.dart';
import 'package:cipher_chat/Screens/User/register.dart';
import 'package:cipher_chat/Screens/User/welcome.dart';
import 'package:flutter/material.dart';

import 'globalState/Messages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      // initialRoute: '/',
      initialRoute: '/main',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/main': (context) => MessagesMainScreen(),
        '/messages': (context) {
          return MessagesListScreen(
              //contact: ModalRoute.of(context)!.settings.arguments as Contact);
              contact: Contact(name: 'advait', profilePic: ''));
        },
        '/newMessage': (context) => MessagesNewScreen(),
      },
    );
  }
}
