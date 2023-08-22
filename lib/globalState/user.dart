import 'package:basic_utils/basic_utils.dart';

class User {
  String username;
  String token;
  String masterKey;
  String publicKey;
  String privateKey;
  String serverHost;

  RSAPublicKey? rsaPublicKey;
  RSAPrivateKey? rsaPrivateKey;

  User({
    required this.username,
    required this.token,
    required this.masterKey,
    required this.publicKey,
    required this.privateKey,
    required this.serverHost,
  }) {
    rsaPrivateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKey);
    rsaPublicKey = CryptoUtils.rsaPublicKeyFromPem(publicKey);
  }
}
