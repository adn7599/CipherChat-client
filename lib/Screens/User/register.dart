import 'dart:isolate';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:cipher_chat/Components/FormButton.dart';
import 'package:cipher_chat/Screens/Messages/messages_main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/padded_block_cipher/padded_block_cipher_impl.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:pointycastle/src/platform_check/platform_check.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../Components/FormInput.dart';
import '../../globalState/global_state.dart';
import '../../globalState/user.dart';

class RegisterScreen extends StatefulWidget {
  String serverHost;

  RegisterScreen({required this.serverHost});

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
  Future<User>? registerFuture;

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

  void _showDialogRegister() {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return FutureBuilder<User>(
              future: registerFuture,
              builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  String title = 'Registration';
                  String desc = 'Registration Successful';
                  if (snapshot.hasError) {
                    title = 'Registration Unsuccessful';
                    desc = '${snapshot.error}';
                  } else {
                    final User user = snapshot.data!;
                    print("Token : ${user.token}");
                    Provider.of<GlobalState>(context, listen: false)
                        .addUser(user);
                  }
                  return AlertDialog(
                    title: Text(title),
                    content: Text(desc),
                    actions: [
                      TextButton(
                          onPressed: () {
                            if (snapshot.hasError) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          MessagesMainScreen()),
                                  (route) => false);
                            }
                          },
                          child: const Text('Okay'))
                    ],
                  );
                } else {
                  return const AlertDialog(
                    title: Text('Registration'),
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

  Map<String, String> _generateKeyPair(String masterKey) {
    final secureRandom = SecureRandom('Fortuna');
    const bitLen = 2048;
    secureRandom.seed(
        KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));

    final keyGen = RSAKeyGenerator();
    keyGen.init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLen, 64),
        secureRandom));

    final pair = keyGen.generateKeyPair();

    final myPublic = pair.publicKey as RSAPublicKey;
    final myPrivate = pair.privateKey as RSAPrivateKey;

    final myPublicPem = CryptoUtils.encodeRSAPublicKeyToPem(myPublic);
    final myPrivatePem = CryptoUtils.encodeRSAPrivateKeyToPem(myPrivate);

    final sha256 = SHA256Digest();

    final aesKey = sha256.process(
        utf8.encode(masterKey) as Uint8List); //aes256 keysize is 256 bits

    final aesIV = sha256
        .process(aesKey)
        .sublist(0, 16); //aes256 IV size is 128 bits (16 bytes)

    final aesCbcEnc =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

    aesCbcEnc.init(
        true,
        PaddedBlockCipherParameters(
            ParametersWithIV(KeyParameter(aesKey), aesIV), null));

    final plainText = utf8.encode(myPrivatePem) as Uint8List;
    final enc = aesCbcEnc.process(plainText);

    final encPrivateBase64 = base64.encode(enc);

    Map<String, String> ret = {};
    ret['publicKey'] = myPublicPem;
    ret['privateKey'] = myPrivatePem;
    ret['privateKeyEnc'] = encPrivateBase64;

    return ret;
  }

  Future<User> _register() async {
    // var keys =
    //     await Isolate.run(() => _generateKeyPair(_masterKey1Controller.text));

    var keys = _generateKeyPair(_masterKey1Controller.text);

    var res = await http.post(
      Uri.parse('${widget.serverHost}/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "id": _usernameController.text,
        "password": _pass1Controller.text,
        "public_key": keys['publicKey']!,
        "private_key": keys['privateKeyEnc']!,
      }),
    );

    if (res.statusCode == 200) {
      var resBody = jsonDecode(res.body);
      final String token = resBody['token'];
      final User user = User(
          username: _usernameController.text,
          masterKey: _masterKey1Controller.text,
          privateKey: keys['privateKey'] as String,
          publicKey: keys['publicKey'] as String,
          token: token,
          serverHost: widget.serverHost);
      return user;
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
              FormButton(
                  title: 'Submit',
                  onPress: () {
                    if (_usernameController.text == '' ||
                        _masterKey1Controller.text == '' ||
                        _masterKey2Controller.text == '' ||
                        _pass1Controller.text == '' ||
                        _pass2Controller.text == '') {
                      _errorDialog('Empty input!');
                      return;
                    }

                    if (_pass1Controller.text != _pass2Controller.text) {
                      _errorDialog("Passwords don't match");
                      return;
                    }

                    if (_masterKey1Controller.text !=
                        _masterKey2Controller.text) {
                      _errorDialog("Master keys don't match");
                      return;
                    }

                    registerFuture = _register();
                    _showDialogRegister();
                  })
            ],
          ),
        ),
      ),
    );
  }
}
