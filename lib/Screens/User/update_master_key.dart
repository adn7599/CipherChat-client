import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:cipher_chat/Components/FormButton.dart';
import 'package:cipher_chat/Components/FormInput.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/api.dart' as pointyAPI;
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:provider/provider.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart'
    as pointPadBC;
import 'package:pointycastle/paddings/pkcs7.dart' as pointyPad;

import '../../globalState/global_state.dart';

class UpdateMasterKeyPasswordScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return UpdateMasterKeyPasswordScreenState();
  }
}

class UpdateMasterKeyPasswordScreenState
    extends State<UpdateMasterKeyPasswordScreen> {
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
    final myPrivatePem = user.privateKey;

    final newMasterKey = _newPass1Controller.text;

    if (_oldPassController.text != user.masterKey) {
      throw Exception('Incorrect master key password!');
    }

    //Encrypting private key with the new masterkey
    final sha256 = SHA256Digest();

    final aesKey = sha256.process(
        utf8.encode(newMasterKey) as Uint8List); //aes256 keysize is 256 bits

    final aesIV = sha256
        .process(aesKey)
        .sublist(0, 16); //aes256 IV size is 128 bits (16 bytes)

    final aesCbcEnc = pointPadBC.PaddedBlockCipherImpl(
        pointyPad.PKCS7Padding(), CBCBlockCipher(AESEngine()));

    aesCbcEnc.init(
        true,
        pointyAPI.PaddedBlockCipherParameters(
            pointyAPI.ParametersWithIV(pointyAPI.KeyParameter(aesKey), aesIV),
            null));

    final plainText = utf8.encode(myPrivatePem) as Uint8List;
    final enc = aesCbcEnc.process(plainText);

    final encPrivateBase64 = base64.encode(enc);

    var res = await http.post(
      Uri.parse('$serverHost/auth/changeMasterKey'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        "new_encrypted_private_key": encPrivateBase64,
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
        title: const Text('Change Master Key Password'),
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
