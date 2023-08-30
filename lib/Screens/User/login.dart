import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:http/http.dart' as http;
import 'package:cipher_chat/Components/FormButton.dart';
import 'package:cipher_chat/Components/FormInput.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart'
    as pointPadBC;
import 'package:pointycastle/paddings/pkcs7.dart' as pointyPad;
import 'package:provider/provider.dart';

import '../../globalState/global_state.dart';
import '../../globalState/user.dart';
import '../Messages/messages_main.dart';

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
  Future<User>? _loginFuture;

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

  void _showDialogLogin() {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return FutureBuilder<User>(
              future: _loginFuture,
              builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    String title = 'Login Unsuccessful';
                    String desc = '${snapshot.error}';

                    return AlertDialog(
                      title: Text(title),
                      content: Text(desc),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Okay'))
                      ],
                    );
                  } else {
                    final User user = snapshot.data!;
                    String title = 'Logging In';
                    String desc = 'Login Successful';
                    debugPrint("Token : ${user.token}");
                    final globalState =
                        Provider.of<GlobalState>(context, listen: false);

                    return AlertDialog(
                      title: Text(title),
                      content: Text(desc),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              final userBackupOld = globalState.userBackupOld;
                              if (userBackupOld != null) {
                                //previous user found
                                //checking if new login matches old user (to get backup chats)
                                if (userBackupOld.username != user.username) {
                                  //Clearing previous user's data
                                  await globalState.clearAll();
                                }
                                //no previous user found
                              }
                              await globalState.addUser(user);
                              await globalState.initMessageWebSocket();
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MessagesMainScreen()),
                                  (route) => false);
                            },
                            child: const Text('Okay'))
                      ],
                    );
                  }
                } else {
                  return const AlertDialog(
                    title: Text('Logging In'),
                    content: Row(children: [
                      CircularProgressIndicator(),
                      SizedBox(
                        width: 16.0,
                      ),
                      Text('Submitting'),
                    ]),
                    actions: [],
                  );
                }
              });
        });
  }

  Future<User> _login() async {
    var res = await http.post(
      Uri.parse('${widget.serverHost}/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "id": _usernameController.text,
        "password": _passwordController.text,
      }),
    );

    if (res.statusCode == 200) {
      try {
        var resBody = jsonDecode(res.body);
        final String token = resBody['token'];
        final String publicKey = resBody['public_key'];
        final String encPrivateKeyBase64 = resBody['private_key'];

        final sha256 = SHA256Digest();

        final aesKey = sha256.process(utf8.encode(_masterSecretController.text)
            as Uint8List); //aes256 keysize is 256 bits

        final aesIV = sha256
            .process(aesKey)
            .sublist(0, 16); //aes256 IV size is 128 bits (16 bytes)

        final Uint8List encPrivateKey = base64.decode(encPrivateKeyBase64);

        final aesCbcDec = pointPadBC.PaddedBlockCipherImpl(
            pointyPad.PKCS7Padding(), CBCBlockCipher(AESEngine()));

        aesCbcDec.init(
            false,
            PaddedBlockCipherParameters(
                ParametersWithIV(KeyParameter(aesKey), aesIV), null));

        final decPrivateKey = aesCbcDec.process(encPrivateKey);
        final privateKey = String.fromCharCodes(decPrivateKey);
        debugPrint('Decrypted private key: $privateKey');

        final User user = User(
            username: _usernameController.text,
            masterKey: _masterSecretController.text,
            privateKey: privateKey,
            publicKey: publicKey,
            token: token,
            serverHost: widget.serverHost);

        return user;
      } on ArgumentError {
        throw Exception('Incorrect Master Secret Key!');
      }
      // final decPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKey);
      // final decPublicKey = CryptoUtils.rsaPublicKeyFromPem(publicKey);
    } else if (res.statusCode == 400) {
      var resBody = jsonDecode(res.body);
      throw Exception(resBody['error']);
    } else {
      throw Exception('Server responded with status code ${res.statusCode}');
    }
  }

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
          FormButton(
              title: 'Submit',
              onPress: () {
                if (_usernameController.text == '' ||
                    _passwordController.text == '' ||
                    _masterSecretController.text == '') {
                  _errorDialog('Empty input!');
                  return;
                }
                _loginFuture = _login();
                _showDialogLogin();
              })
        ]),
      )),
    );
  }
}
