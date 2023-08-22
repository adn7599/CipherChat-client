import 'package:cipher_chat/Screens/User/welcome.dart';
import 'package:cipher_chat/globalState/global_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../globalState/messages.dart';

class MessagesMainScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MessagesMainState();
  }
}

class _MessagesMainState extends State<MessagesMainScreen> {
  final List<Contact> contacts = <Contact>[
    Contact(name: 'advait', profilePic: '', publickey: ''),
    Contact(name: 'naik', profilePic: '', publickey: ''),
  ];

  void _handlePopMenu(String value) {
    switch (value) {
      case 'settings':
        break;
      case 'logout':
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Logout'),
                content: const Text('Do you really wish to logout?'),
                actions: <Widget>[
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('No')),
                  TextButton(
                      onPressed: () {
                        Provider.of<GlobalState>(context, listen: false)
                            .clearState()
                            .then((_) {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => WelcomeScreen()),
                              (route) => false);
                        });
                      },
                      child: const Text('Yes'))
                ],
              );
            });
        break;
      default:
        print('Invalid option selected');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: <Widget>[
          PopupMenuButton(
              onSelected: _handlePopMenu,
              itemBuilder: (BuildContext context) {
                return ['settings', 'logout'].map((String choice) {
                  return PopupMenuItem(value: choice, child: Text(choice));
                }).toList();
              })
        ],
      ),
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
