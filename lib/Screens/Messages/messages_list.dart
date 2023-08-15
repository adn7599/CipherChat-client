import 'package:flutter/material.dart';

import '../../globalState/Messages.dart';

class MessagesListScreen extends StatefulWidget {
  final Contact contact;

  MessagesListScreen({required this.contact});

  @override
  State<StatefulWidget> createState() {
    return MessageListState();
  }
}

class MessageListState extends State<MessagesListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
          radius: 20.0,
          child: Icon(Icons.person, color: Colors.black, size: 24.0),
        ),
        SizedBox(width: 8.0),
        Text(widget.contact.name)
      ])),
    );
  }
}
