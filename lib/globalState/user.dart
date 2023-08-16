class User {
  String username;
  String token;
  String masterKey;
  String publicKey;
  String privateKey;

  User(
      {required this.username,
      required this.token,
      required this.masterKey,
      required this.publicKey,
      required this.privateKey});
}
