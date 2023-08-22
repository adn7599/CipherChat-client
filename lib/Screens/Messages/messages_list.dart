import 'package:flutter/material.dart';

import '../../globalState/messages.dart';

class MessagesListScreen extends StatefulWidget {
  final Contact contact;

  MessagesListScreen({required this.contact});

  @override
  State<StatefulWidget> createState() {
    return MessageListState();
  }
}

class MessageListState extends State<MessagesListScreen> {
  final TextEditingController _messageController = TextEditingController();
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
        SizedBox(width: 12.0),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contact.name),
            const Text(
              'Online',
              style: TextStyle(fontSize: 12.0),
            ),
          ],
        ),
      ])),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: widget.contact.messages.length,
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.only(
                        left: 14, right: 14, top: 10, bottom: 10),
                    child: Align(
                      alignment:
                          (widget.contact.messages[index].type == "received"
                              ? Alignment.topLeft
                              : Alignment.topRight),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color:
                              (widget.contact.messages[index].type == "received"
                                  ? Colors.grey.shade200
                                  : Colors.black),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.contact.messages[index].body,
                          style: TextStyle(
                              fontSize: 15,
                              color: widget.contact.messages[index].type ==
                                      "received"
                                  ? Colors.black
                                  : Colors.white),
                        ),
                      ),
                    ),
                  );
                }),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black, width: 0.7)),
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Write your message..',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
