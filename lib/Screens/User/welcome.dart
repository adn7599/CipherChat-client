import 'package:cipher_chat/Components/FormButton.dart';
import 'package:cipher_chat/Components/FormInput.dart';
import 'package:cipher_chat/Screens/User/login.dart';
import 'package:cipher_chat/Screens/User/register.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  TextEditingController serverHostController =
      TextEditingController(text: 'http://192.168.0.101:8080');

  void _invalidServerHost() {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Invalid Server Host'),
            content: const SingleChildScrollView(
                child: ListBody(
              children: <Widget>[
                Text('Please enter a valid server host'),
              ],
            )),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Okay'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Cipher Chat'),
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
                width: MediaQuery.of(context).size.width * 0.3,
                child: Image.asset('assets/icon.png'),
              ),
              const SizedBox(
                height: 12.0,
              ),
              Container(
                margin: const EdgeInsets.all(16.0),
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
              FormInput(title: 'Server Host', controller: serverHostController),
              const SizedBox(
                height: 16.0,
              ),
              FormButton(
                  title: 'Register',
                  onPress: () {
                    if (serverHostController.text == '') {
                      _invalidServerHost();
                      return;
                    }
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => RegisterScreen(
                              serverHost: serverHostController.text,
                            )));
                  }),
              const SizedBox(
                height: 16.0,
              ),
              FormButton(
                  title: 'Login',
                  onPress: () {
                    if (serverHostController.text == '') {
                      _invalidServerHost();
                      return;
                    }
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => LoginScreen(
                              serverHost: serverHostController.text,
                            )));
                  })
            ],
          ),
        ),
      ),
    );
  }
}
