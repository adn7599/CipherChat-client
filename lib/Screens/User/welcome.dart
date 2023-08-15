import 'package:cipher_chat/Components/FormButton.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Cipher Chat'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                child: Image.asset('assets/icon.png'),
              ),
              const SizedBox(
                height: 12.0,
              ),
              Container(
                margin: EdgeInsets.all(16.0),
                child: const Text(
                  'Cipher Chat',
                  style: TextStyle(
                    fontSize: 44,
                  ),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              FormButton(
                  title: 'Register',
                  onPress: () {
                    Navigator.pushNamed(context, '/register');
                  }),
              const SizedBox(
                height: 16.0,
              ),
              FormButton(
                  title: 'Login',
                  onPress: () {
                    Navigator.pushNamed(context, '/login');
                  })
            ],
          ),
        ),
      ),
    );
  }
}
