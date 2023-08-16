import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../Messages.dart';
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
            'CREATE TABLE USER(username TEXT, token TEXT,master_key TEXT, public_key TEXT, private_key TEXT);');
        await db.execute(
            'CREATE TABLE CONTACTS(id INT PRIMARY KEY AUTOINCREMENT,username TEXT, public_key TEXT);');
        await db.execute(
            'CREATE TABLE CHATS(id INT PRIMARY KEY AUTOINCREMENT,username TEXT,type TEXT, body TEXT, time INTEGER);');
      },
    );
  }

  Future<void> createUser(User user) async {
    await _database.rawInsert(
        'INSERT INTO USER(username,token,master_key,public_key,private_key) VALUES(?,?,?,?,?);',
        [
          user.username,
          user.token,
          user.masterKey,
          user.publicKey,
          user.privateKey
        ]);
  }

  Future<User> getUser() async {
    var res = (await _database.rawQuery('SELECT * FROM USER;'))[0];
    return User(
      username: res['username'] as String,
      token: res['token'] as String,
      masterKey: res['master_key'] as String,
      publicKey: res['public_key'] as String,
      privateKey: res['private_key'] as String,
    );
  }

  Future<List<Contact>> _getContacts() async {
    var res = await _database.rawQuery('SELECT * FROM CONTACTS;');

    List<Contact> cons = res.map((e) {
      return Contact(
        name: e['username'] as String,
        profilePic: '',
        publickey: e['public_key'] as String,
      );
    }) as List<Contact>;

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
          type: msg['type'] as String,
          body: msg['body'] as String,
          time: DateTime.fromMillisecondsSinceEpoch(['time'] as int),
        ));
      }

      c.messages = messages;
    }
    return cons;
  }

  Future<void> addMessage(Contact con, Message msg) async {
    await _database.rawInsert(
        'INSERT INTO CHATS(username,type,body,time), VALUE(?,?,?,?);',
        [con.name, msg.type, msg.body, msg.time.millisecondsSinceEpoch]);
  }
}
