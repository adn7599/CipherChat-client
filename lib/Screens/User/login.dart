import 'package:cipher_chat/Components/FormButton.dart';
import 'package:cipher_chat/Components/FormInput.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  String serverHost;

  LoginScreen({required this.serverHost});

  @override
  State<StatefulWidget> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _masterSecretController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          const SizedBox(
            height: 32.0,
          ),
          FormInput(title: 'Username', controller: _usernameController),
          const SizedBox(
            height: 16.0,
          ),
          FormInput(
            title: 'Password',
            controller: _passwordController,
            isHidden: true,
          ),
          const SizedBox(
            height: 16.0,
          ),
          FormInput(
              title: 'Master Secret Key',
              controller: _masterSecretController,
              isHidden: true),
          const SizedBox(
            height: 32.0,
          ),
          FormButton(title: 'Submit', onPress: () {})
        ]),
      )),
    );
  }
}
