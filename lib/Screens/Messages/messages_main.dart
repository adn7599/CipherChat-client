import 'package:flutter/material.dart';

import '../../globalState/Messages.dart';

class MessagesMainScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MessagesMainState();
  }
}

class _MessagesMainState extends State<MessagesMainScreen> {
  final List<Contact> contacts = <Contact>[
    Contact(name: 'advait', profilePic: ''),
    Contact(name: 'naik', profilePic: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: contacts.isEmpty
          ? const Center(child: Text('No Messages!'))
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/messages',
                        arguments: contacts[index]);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    // decoration: BoxDecoration(border: BorderDirectional(bottom: BorderSide())),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 26.0,
                          child: Icon(Icons.person,
                              color: Colors.white, size: 40.0),
                        ),
                        const SizedBox(
                          width: 12.0,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contacts[index].name),
                            Text(
                              contacts[index].getLatestMessage().body,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontWeight: FontWeight.w100,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(contacts[index].getLatestTime(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w100, fontSize: 16.0)),
                      ],
                    ),
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/newMessage');
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.message),
      ),
    );
  }
}
