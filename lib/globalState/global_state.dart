import 'package:cipher_chat/globalState/Database/database.dart';
import 'package:cipher_chat/globalState/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../Screens/User/welcome.dart';
import 'messages.dart';

class GlobalState extends ChangeNotifier {
  User? _user;
  User? _userBackupOld;
  List<Contact> _contacts = [];

  MyDatabase? _db;

  Future<void> loadState() async {
    _db = await MyDatabase.getDatabase();
    _user = await _db!.getUser();
    _userBackupOld = await _db!.getUserBackupOld();
    _contacts = await _db!.loadChats();
  }

  Future<void> clearOnlyUser() async {
    await _db!.clearOnlyUser();
    _user = null;
    // _contacts = null;
  }

  Future<void> clearAll() async {
    await _db!.clearAll();
    _user = null;
    _contacts = [];
  }

  User? get user => _user;
  User? get userBackupOld => _userBackupOld;
  List<Contact>? get contacts => _contacts;

  Future<void> addUser(User user) async {
    await _db!.createUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> addContact(Contact con) async {
    await _db!.addContact(con);
    _contacts!.add(con);
    // notifyListeners();
  }

  Future<void> addMessage(Contact con, Message msg) async {
    await _db!.addMessage(con, msg);
    for (Contact c in _contacts!) {
      if (c.name == con.name) {
        //Found contact in state
        // con.messages.add(msg); //for new contact
        c.messages.add(msg);
      }
    }
    notifyListeners();
  }
}

void tokenExpiredLogoutHandler(BuildContext context, GlobalState gs) {
  showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Token Expired'),
          content: const SingleChildScrollView(
              child: ListBody(
            children: <Widget>[
              Text('Please login again'),
            ],
          )),
          actions: [
            TextButton(
                onPressed: () {
                  gs.clearOnlyUser().then((_) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => WelcomeScreen()),
                        (route) => false);
                  });
                },
                child: const Text('Okay'))
          ],
        );
      });
}
