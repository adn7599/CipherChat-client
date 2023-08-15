import 'package:cipher_chat/Components/FormButton.dart';
import 'package:flutter/material.dart';

import '../../Components/FormInput.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pass1Controller = TextEditingController();
  final TextEditingController _pass2Controller = TextEditingController();
  final TextEditingController _masterKey1Controller = TextEditingController();
  final TextEditingController _masterKey2Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 32.0,
              ),
              FormInput(title: 'Username', controller: _usernameController),
              const SizedBox(
                height: 16.0,
              ),
              FormInput(
                title: 'Password',
                controller: _pass1Controller,
                isHidden: true,
              ),
              const SizedBox(
                height: 16.0,
              ),
              FormInput(
                title: 'Re-enter your password',
                controller: _pass2Controller,
                isHidden: true,
              ),
              const SizedBox(
                height: 16.0,
              ),
              FormInput(
                title: 'Master Secret key',
                controller: _masterKey1Controller,
                isHidden: true,
              ),
              const SizedBox(
                height: 16.0,
              ),
              FormInput(
                title: 'Re-enter your Master Secret key',
                controller: _masterKey2Controller,
                isHidden: true,
              ),
              const SizedBox(
                height: 16.0,
              ),
              const SizedBox(
                height: 32.0,
              ),
              FormButton(title: 'Submit', onPress: () {})
            ],
          ),
        ),
      ),
    );
  }
}
