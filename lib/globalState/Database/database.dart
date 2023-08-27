import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../messages.dart';
import '../user.dart';

class MyDatabase {
  static MyDatabase? _db; //Singleton

  static Future<MyDatabase> getDatabase() async {
    if (_db == null) {
      _db = MyDatabase._internal();
      await _db!.initDB();
    }
    return _db!;
  }

  late Database _database;

  MyDatabase._internal(); //Private constructor

  Future<void> initDB() async {
    String path = join(await getDatabasesPath(), 'cipherChat.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE USER(username TEXT, token TEXT,master_key TEXT, public_key TEXT, private_key TEXT, server_host TEXT);');
        await db.execute(
            'CREATE TABLE USER_BACKUP(username TEXT, token TEXT,master_key TEXT, public_key TEXT, private_key TEXT, server_host TEXT);');
        await db.execute(
            'CREATE TABLE CONTACTS(id INTEGER PRIMARY KEY AUTOINCREMENT,username TEXT, public_key TEXT);');
        await db.execute(
            'CREATE TABLE CHATS(id INTEGER PRIMARY KEY AUTOINCREMENT,username TEXT,type TEXT, body TEXT, time INTEGER);');
      },
    );
  }

  Future<void> clearOnlyUser() async {
    await _database.rawDelete('DELETE FROM USER;');
  }

  Future<void> clearAll() async {
    await _database.rawDelete('DELETE FROM USER;');
    await _database.rawDelete('DELETE FROM CONTACTS;');
    await _database.rawDelete('DELETE FROM CHATS;');
  }

  Future<void> createUser(User user) async {
    await _database.rawInsert(
        'INSERT INTO USER(username,token,master_key,public_key,private_key,server_host) VALUES(?,?,?,?,?,?);',
        [
          user.username,
          user.token,
          user.masterKey,
          user.publicKey,
          user.privateKey,
          user.serverHost,
        ]);

    await _database.rawDelete('DELETE FROM USER_BACKUP;');

    await _database.rawInsert(
        'INSERT INTO USER_BACKUP(username,token,master_key,public_key,private_key,server_host) VALUES(?,?,?,?,?,?);',
        [
          user.username,
          user.token,
          user.masterKey,
          user.publicKey,
          user.privateKey,
          user.serverHost,
        ]);
  }

  Future<User?> getUser() async {
    var result = (await _database.rawQuery('SELECT * FROM USER;'));
    //var res = (await _database.rawQuery('SELECT * FROM USER;'))[0];

    if (result.isEmpty) {
      return null;
    }

    var res = result[0];

    return User(
      username: res['username'] as String,
      token: res['token'] as String,
      masterKey: res['master_key'] as String,
      publicKey: res['public_key'] as String,
      privateKey: res['private_key'] as String,
      serverHost: res['server_host'] as String,
    );
  }

  Future<User?> getUserBackupOld() async {
    var result = (await _database.rawQuery('SELECT * FROM USER_BACKUP;'));
    //var res = (await _database.rawQuery('SELECT * FROM USER;'))[0];

    if (result.isEmpty) {
      return null;
    }

    var res = result[0];

    return User(
      username: res['username'] as String,
      token: res['token'] as String,
      masterKey: res['master_key'] as String,
      publicKey: res['public_key'] as String,
      privateKey: res['private_key'] as String,
      serverHost: res['server_host'] as String,
    );
  }

  Future<List<Contact>> _getContacts() async {
    var res = await _database.rawQuery('SELECT * FROM CONTACTS;');
    List<Contact> cons = [];

    if (res.isEmpty) return cons;

    for (var e in res) {
      cons.add(Contact(
        name: e['username'] as String,
        profilePic: '',
        publickey: e['public_key'] as String,
      ));
    }

    return cons;
  }

  Future<void> addContact(Contact con) async {
    await _database.rawInsert(
        'INSERT INTO CONTACTS(username,public_key) VALUES(?,?);',
        [con.name, con.publickey]);
  }

  Future<List<Contact>> loadChats() async {
    List<Contact> cons = await _getContacts();

    for (Contact c in cons) {
      var res = await _database.rawQuery(
          'SELECT * FROM CHATS WHERE username = ? ORDER BY time ASC;',
          [c.name]);

      //Creating a list of messages to add to the contact
      List<Message> messages = <Message>[];
      for (var msg in res) {
        messages.add(Message(
          type: (msg['type'] as String) == 'R'
              ? MessageType.Received
              : MessageType.Sent,
          body: msg['body'] as String,
          time: DateTime.fromMillisecondsSinceEpoch(msg['time'] as int),
        ));
      }

      c.messages = messages;
    }
    return cons;
  }

  Future<void> addMessage(Contact con, Message msg) async {
    await _database.rawInsert(
        'INSERT INTO CHATS(username,type,body,time) VALUES(?,?,?,?);', [
      con.name,
      msg.type == MessageType.Received ? 'R' : 'S',
      msg.body,
      msg.time.millisecondsSinceEpoch
    ]);
  }
}
