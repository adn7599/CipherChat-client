import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:cipher_chat/globalState/messages.dart';

import 'package:pointycastle/src/platform_check/platform_check.dart';

import '../user.dart';

void encryptMessage(Map<String, dynamic> params) {
  // final RSAPublicKey myPublicKey =
  //     CryptoUtils.rsaPublicKeyFromPem(user.publicKey);
  final SendPort gsSendPort = params["sendPort"];
  final String myPrivateKeyParam = params['myPrivateKey'];
  final String conPublicKey = params['conPublicKey'];
  final String message = params['message'];
  final String messageTime = params['messageTime'];

  final RSAPrivateKey myPrivateKey =
      CryptoUtils.rsaPrivateKeyFromPem(myPrivateKeyParam);

  final RSAPublicKey conPubKey = CryptoUtils.rsaPublicKeyFromPem(conPublicKey);

  //generating random aeskey for symmetric encryption
  final secureRandom = SecureRandom('Fortuna');
  secureRandom.seed(
      KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));

  final randNum = secureRandom.nextUint32().toString();

  final sha256 = SHA256Digest();

  final aesKey = sha256.process(utf8.encode(randNum) as Uint8List);
  final aesIV = sha256.process(aesKey).sublist(0, 16); //aes256 IV is 128 bit

  //encrypting msg json with aes key
  final aesCbcEnc =
      PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

  aesCbcEnc.init(
      true,
      PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(aesKey), aesIV), null));
  final msgJson = jsonEncode({
    "time": messageTime,
    "message": message,
  });

  final msgJsonBase64 = base64Encode(utf8.encode(msgJson) as Uint8List);

  final Uint8List encMsg =
      aesCbcEnc.process(utf8.encode(msgJsonBase64) as Uint8List);

  final String encMsgBase64 = base64Encode(encMsg);

  //Encrypting aeskey token
  final rsaEncryptor = OAEPEncoding(RSAEngine());
  rsaEncryptor.init(true, PublicKeyParameter<RSAPublicKey>(conPubKey));
  final Uint8List encToken = rsaEncryptor.process(aesKey);

  final String encTokenBase64 = base64Encode(encToken);

  //Signing the message with my private key
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(myPrivateKey));
  final RSASignature sign =
      signer.generateSignature(utf8.encode(msgJsonBase64) as Uint8List);

  final signBase64 = base64Encode(sign.bytes);

  gsSendPort.send({
    "token": encTokenBase64, //RSAEnc(aeskey)
    "message": encMsgBase64,
    "sign": signBase64,
  });
}

void decryptMessage(Map<String, dynamic> params) {
  final SendPort sendPort = params["sendPort"];
  try {
    final String myPrivateKeyParam = params["myPrivateKey"];
    final String conPublicKey = params["conPublicKey"];
    final String token = params["token"];
    final String encMessage = params["message"];
    final String sign = params["sign"];

    final RSAPrivateKey myPrivateKey =
        CryptoUtils.rsaPrivateKeyFromPem(myPrivateKeyParam);
    final RSAPublicKey conPubKey =
        CryptoUtils.rsaPublicKeyFromPem(conPublicKey);

    //Decrypting token to get aeskey and IV
    final Uint8List tokenBase64Decoded = base64Decode(token);

    final rsaDecryptor = OAEPEncoding(RSAEngine());
    rsaDecryptor.init(
      false,
      PrivateKeyParameter<RSAPrivateKey>(myPrivateKey),
    );

    final Uint8List aesKey = rsaDecryptor.process(tokenBase64Decoded);

    //getting IV by hash(aeskey)
    final sha256 = SHA256Digest();

    final Uint8List aesIV =
        sha256.process(aesKey).sublist(0, 16); //aes256 IV is 128 bits

    //Decrypting message body
    final aesCbcDec =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

    aesCbcDec.init(
        false,
        PaddedBlockCipherParameters(
            ParametersWithIV(KeyParameter(aesKey), aesIV), null));

    final Uint8List encMsgBase64Decoded = base64Decode(encMessage);

    final decMsgBase64Encoded =
        utf8.decode(aesCbcDec.process(encMsgBase64Decoded));
    final decMsgJsonStr = utf8.decode(base64Decode(decMsgBase64Encoded));

    //verifying signature
    final verifier = RSASigner(SHA256Digest(), '0609608648016503040201');
    verifier.init(false, PublicKeyParameter<RSAPublicKey>(conPubKey));
    final isVerified = verifier.verifySignature(
        utf8.encode(decMsgBase64Encoded) as Uint8List,
        RSASignature(base64Decode(sign)));

    if (!isVerified) {
      throw Exception('Signature verification failure');
    }

    final Map<String, dynamic> decMsgJsonMap = jsonDecode(decMsgJsonStr);

    sendPort.send({
      "error": "false",
      "message": decMsgJsonMap['message'],
      "time": decMsgJsonMap['time'],
    });
  } catch (e) {
    sendPort.send({
      "error": "true",
      "errorMessage": "$e",
    });
  }
}
