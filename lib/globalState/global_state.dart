import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cipher_chat/globalState/Database/database.dart';
import 'package:cipher_chat/globalState/crypto/crypto.dart';
import 'package:cipher_chat/globalState/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../Screens/User/welcome.dart';
import 'messages.dart';

class GlobalState extends ChangeNotifier {
  User? _user;
  User? _userBackupOld;
  List<Contact> _contacts = [];

  WebSocketChannel? _messageWsChannel;
  StreamSubscription<dynamic>? _listenerSub;
  Isolate? _reconnectMessageWsIsolate;
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
    _contacts.add(con);
    // notifyListeners();
  }

  Future<void> addMessage(Contact con, Message msg) async {
    final c = _contacts.firstWhere((element) => element.name == con.name);
    c.messages.add(msg);
    await _db!.addMessage(con, msg);
    // notifyListeners();
  }

  Future<void> initMessageWebSocket() async {
    String url = _user!.serverHost;
    final token = _user!.token;

    if (url.contains('https')) {
      //https
      url = 'wss${url.substring(5)}';
    } else {
      url = 'ws${url.substring(4)}';
    }
    url = '$url/message/websocket/connect';
    print('websocket url: $url');
    final wsChannel = IOWebSocketChannel.connect(url,
        headers: {'Authorization': 'Bearer $token'});
    await wsChannel.ready;

    _messageWsChannel = wsChannel;
    //_receiveBufferedMessages();

    // await _listenerSub?.cancel();
    _listenerSub = _messageWsChannel!.stream.listen((message) {
      _receiveMessageListener(message);
    }, onDone: () async {
      debugPrint("Disconnected");
      _messageWsChannel = null;
      launchReconnectIsolate();
    });

    // _messageWsChannel?.sink.
  }

  Future<void> launchReconnectIsolate() async {
    final receivePort = ReceivePort();

    _reconnectMessageWsIsolate =
        await Isolate.spawn(_reconnectIsolate, receivePort.sendPort);
    final SendPort isolateSendPort = await receivePort.first;
    final newReceivePort = ReceivePort();
    final newSendPort = newReceivePort.sendPort;

    isolateSendPort.send([_user!.serverHost, newSendPort]);

    newReceivePort.listen((message) {
      if ((message as String) == 'server running') {
        debugPrint('server is up');
        initMessageWebSocket().catchError((err) {
          if (err is SocketException) {
            launchReconnectIsolate();
          } else {
            //WebSocketException
            //login again
            _user = null;
            notifyListeners();
          }
        });
      }
    });
  }

  Future<void> closeMessageWebSocket() async {
    debugPrint("closing messages socket");
    try {
      await _listenerSub?.cancel();
      await _messageWsChannel?.sink.close();
      // await _messageWsChannel?.sink.done;
    } on Exception catch (_, e) {
      print("exception while disconnecting ws: $e");
    }
  }

  void cancelReconnectIsolate() async {
    try {
      _reconnectMessageWsIsolate?.kill(priority: Isolate.immediate);
    } catch (e) {
      debugPrint('Error while killing reconnect isolate: $e');
    }
  }

  Future<void> _receiveBufferedMessages(String messages) async {
    // var buff = await _messageWsChannel!.stream.first;
    // debugPrint("buffered: $buff");
    final List<dynamic> json = jsonDecode(messages);

    for (var b in json) {
      final String sender = b['sender'];
      final String sendTime = b['send_time'];
      final String message = b['message'];
      var conIndex = _contacts.indexWhere((element) => element.name == sender);

      if (conIndex == -1) {
        //not found
        //need to add contact
        final res = await http.get(
          Uri.parse('${_user!.serverHost}/user/search?username=$sender'),
          headers: <String, String>{
            HttpHeaders.authorizationHeader: 'Basic ${user!.token}',
          },
        );

        if (res.statusCode != 200) {
          continue;
        }

        final publicKey = jsonDecode(res.body)[0]['public_key'];

        final con = Contact(name: sender, profilePic: '', publickey: publicKey);
        await addContact(con);
        conIndex = _contacts.length - 1;
      }
      final con = _contacts[conIndex];

      final msgJsonMap = jsonDecode(message);

      final myReceiver = ReceivePort();
      await Isolate.spawn(decryptMessage, {
        "sendPort": myReceiver.sendPort,
        "myPrivateKey": _user!.privateKey,
        "conPublicKey": con.publickey,
        "token": msgJsonMap['token'],
        "message": msgJsonMap['message'],
        "sign": msgJsonMap['sign'],
      });
      final decResult = await myReceiver.first;

      debugPrint('Decrypted result from isolate: $decResult');

      if (decResult['error'] == 'true') {
        continue;
      }

      final msg = Message(
          type: MessageType.Received,
          body: decResult['message'],
          time: DateTime.fromMillisecondsSinceEpoch(
              int.parse(decResult['time'])));
      addMessage(con, msg);
    }
    notifyListeners();
  }

  Future<void> _receiveMessageListener(String msge) async {
    debugPrint('Received message: $msge');
    if (msge.startsWith('[')) {
      //buffered messages
      _receiveBufferedMessages(msge);
    } else {
      final json = jsonDecode(msge);

      final String type = json['type'];

      if (type == 'sent_response') {
        debugPrint('sent_response: $msge');
        return;
      }

      final String sender = json['sender'];
      final String sendTime = json['send_time'];
      final String message = json['message'];
      var conIndex = _contacts.indexWhere((element) => element.name == sender);

      if (conIndex == -1) {
        //not found
        //need to add contact
        final res = await http.get(
          Uri.parse('${_user!.serverHost}/user/search?username=$sender'),
          headers: <String, String>{
            HttpHeaders.authorizationHeader: 'Basic ${user!.token}',
          },
        );

        if (res.statusCode != 200) {
          return;
        }

        final publicKey = jsonDecode(res.body)[0]['public_key'];

        final con = Contact(name: sender, profilePic: '', publickey: publicKey);
        await addContact(con);
        conIndex = _contacts.length - 1;
      }
      final con = _contacts[conIndex];
      //decrypting message

      final msgJsonMap = jsonDecode(message);

      final myReceiver = ReceivePort();
      await Isolate.spawn(decryptMessage, {
        "sendPort": myReceiver.sendPort,
        "myPrivateKey": _user!.privateKey,
        "conPublicKey": con.publickey,
        "token": msgJsonMap['token'],
        "message": msgJsonMap['message'],
        "sign": msgJsonMap['sign'],
      });
      final decResult = await myReceiver.first;

      debugPrint('Decrypted result from isolate: $decResult');

      if (decResult['error'] == 'true') {
        return;
      }

      final msg = Message(
          type: MessageType.Received,
          body: decResult['message'],
          time: DateTime.fromMillisecondsSinceEpoch(
              int.parse(decResult['time'])));
      addMessage(con, msg);
      notifyListeners();
    }
  }

  Future<void> sendMessage(Contact con, Message msg) async {
    if (_messageWsChannel == null) {
      return;
    }
    final myReceiver = ReceivePort();
    await Isolate.spawn(encryptMessage, {
      "sendPort": myReceiver.sendPort,
      "myPrivateKey": _user!.privateKey,
      "conPublicKey": con.publickey,
      "message": msg.body,
      "messageTime": msg.time.millisecondsSinceEpoch.toString(),
    });
    final encResult = await myReceiver.first;
    debugPrint('Encryption result from isolate: $encResult');
    final encMsgJson = jsonEncode(encResult);

    final json = jsonEncode({
      "receiver": con.name,
      "send_time": msg.time.millisecondsSinceEpoch.toString(),
      "message": encMsgJson,
    });
    _messageWsChannel!.sink.add(json);
    await addMessage(con, msg);
    notifyListeners();
  }
}

Future<void> _reconnectIsolate(SendPort gsSendPort) async {
  debugPrint('Running reconnect isolate');

  final ReceivePort myReceivePort = ReceivePort();
  final SendPort mySendPort = myReceivePort.sendPort;
  gsSendPort.send(mySendPort);
  final sentMsg = await myReceivePort.first;
  final String serverHost = sentMsg[0];
  final SendPort gsNewSendPort = sentMsg[1];

  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Trying to reconnect websocket');

    try {
      final res = await http.get(Uri.parse('$serverHost/ping'));
      if (res.statusCode == 200) {
        gsNewSendPort.send('server running');
        break;
      }
    } catch (e) {
      debugPrint('Reconnect exception: $e');
    }
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
                onPressed: () async {
                  await gs.clearOnlyUser();
                  await gs.closeMessageWebSocket();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => WelcomeScreen()),
                      (route) => false);
                },
                child: const Text('Okay'))
          ],
        );
      });
}
