import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:cipher_chat/Components/FormButton.dart';
import 'package:cipher_chat/Components/FormInput.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../globalState/global_state.dart';

class UpdatePasswordScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UpdatePasswordScreenState();
  }
}

class UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPass1Controller = TextEditingController();
  final TextEditingController _newPass2Controller = TextEditingController();

  Future<void>? _changePassFuture;

  void _errorDialog(String msg) {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Invalid Input'),
            content: SingleChildScrollView(
                child: ListBody(
              children: <Widget>[
                Text(msg),
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

  void _changePasswordDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return FutureBuilder(
            future: _changePassFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return AlertDialog(
                    title: const Text('Change password unsuccessful'),
                    content: Text('${snapshot.error}'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Okay'))
                    ],
                  );
                } else {
                  return AlertDialog(
                    title: const Text('Change password'),
                    content: const Text('Changed password successfully'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            _oldPassController.text = "";
                            _newPass1Controller.text = "";
                            _newPass2Controller.text = "";

                            Navigator.of(context).pop();
                          },
                          child: const Text('Okay'))
                    ],
                  );
                }
              } else {
                return const AlertDialog(
                    title: Text('Change Password'),
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(
                          width: 16.0,
                        ),
                        Text('Submitting'),
                      ],
                    ),
                    actions: []);
              }
            });
      },
    );
  }

  Future<void> _changePassword() async {
    final user = Provider.of<GlobalState>(context, listen: false).user!;
    final serverHost = user.serverHost;
    final token = user.token;

    var res = await http.post(
      Uri.parse('$serverHost/auth/changePassword'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        "old_password": _oldPassController.text,
        "new_password": _newPass1Controller.text,
      }),
    );

    if (res.statusCode != 200) {
      final String error = jsonDecode(res.body)['error'];
      throw Exception(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(children: [
            const SizedBox(
              height: 24.0,
            ),
            FormInput(
              title: 'Old Password',
              controller: _oldPassController,
              isHidden: true,
            ),
            const SizedBox(
              height: 16.0,
            ),
            FormInput(
              title: 'New Password',
              controller: _newPass1Controller,
              isHidden: true,
            ),
            const SizedBox(
              height: 16.0,
            ),
            FormInput(
              title: 'Re-enter new Password',
              controller: _newPass2Controller,
              isHidden: true,
            ),
            const SizedBox(
              height: 32.0,
            ),
            FormButton(
                title: 'Submit',
                onPress: () {
                  if (_oldPassController.text == '' ||
                      _newPass1Controller.text == '' ||
                      _newPass2Controller.text == '') {
                    _errorDialog('Empty input!');
                    return;
                  }

                  if (_newPass1Controller.text != _newPass2Controller.text) {
                    _errorDialog('New passwords don\'t match');
                    return;
                  }

                  _changePassFuture = _changePassword();
                  _changePasswordDialog();
                }),
          ]),
        ),
      ),
    );
  }
}
