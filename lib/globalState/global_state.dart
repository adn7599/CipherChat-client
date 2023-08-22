import 'package:cipher_chat/globalState/Database/database.dart';
import 'package:cipher_chat/globalState/user.dart';
import 'package:flutter/foundation.dart';

import 'messages.dart';

class GlobalState extends ChangeNotifier {
  User? _user;
  List<Contact>? _contacts;

  MyDatabase? _db;

  Future<void> loadState() async {
    _db = await MyDatabase.getDatabase();
    _user = await _db!.getUser();
    _contacts = await _db!.loadChats();
  }

  Future<void> clearState() async {
    await _db!.clear();
    _user = null;
    _contacts = null;
  }

  User? get user => _user;
  List<Contact>? get contacts => _contacts;

  Future<void> addUser(User user) async {
    await _db!.createUser(user);
    _user = user;
    notifyListeners();
  }

  Future<void> addContact(Contact con) async {
    await _db!.addContact(con);
    _contacts!.add(con);
    notifyListeners();
  }

  Future<void> addMessage(Contact con, Message msg) async {
    await _db!.addMessage(con, msg);
    for (Contact c in _contacts!) {
      if (c.name == con.name) {
        //Found contact in state
        con.messages.add(msg);
      }
    }
    notifyListeners();
  }
}
