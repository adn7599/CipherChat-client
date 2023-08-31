import 'package:cipher_chat/Screens/Messages/messages_list.dart';
import 'package:cipher_chat/Screens/Messages/messages_new.dart';
import 'package:cipher_chat/Screens/User/show_key_QR.dart';
import 'package:cipher_chat/Screens/User/update_password.dart';
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
  void _handlePopMenu(String value) {
    switch (value) {
      case 'Key verification QR':
        debugPrint('Pressed Key verification QR');
        final user = Provider.of<GlobalState>(context, listen: false).user!;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                ShowKeyQRScreen(user.username, user.publicKey)));
        break;
      case 'Update password':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => UpdatePasswordScreen()));
        break;
      case 'Update master secret key':
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
                      onPressed: () async {
                        final gs =
                            Provider.of<GlobalState>(context, listen: false);
                        gs.cancelReconnectIsolate();
                        await gs.clearOnlyUser();
                        await gs.closeMessageWebSocket();

                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => WelcomeScreen()),
                            (route) => false);
                      },
                      child: const Text('Yes'))
                ],
              );
            });
        break;
      default:
        debugPrint('Invalid option selected');
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
                return [
                  'Key verification QR',
                  'Update password',
                  'Update master secret key',
                  'logout'
                ].map((String choice) {
                  return PopupMenuItem(value: choice, child: Text(choice));
                }).toList();
              })
        ],
      ),
      body: Consumer<GlobalState>(builder: (context, gs, child) {
        if (gs.user == null) {
          //Websocket connection token expired; need to login again
          Future.delayed(const Duration(seconds: 3), () {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Your token has expired login again!'),
                    actions: <Widget>[
                      TextButton(
                          onPressed: () async {
                            final gs = Provider.of<GlobalState>(context,
                                listen: false);
                            await gs.clearOnlyUser();
                            await gs.closeMessageWebSocket();

                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => WelcomeScreen()),
                                (route) => false);
                          },
                          child: const Text('Okay'))
                    ],
                  );
                });
          });
        }

        final contacts = gs.contacts ?? <Contact>[];
        contacts.sort((Contact first, Contact second) {
          if (first.latestMessage.time.isAfter(second.latestMessage.time)) {
            return -1;
          } else {
            return 1;
          }
        });
        return contacts.isEmpty
            ? const Center(child: Text('No Messages!'))
            : ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return MessagesListScreen(
                            contact: contacts[index], isNew: false);
                      }));
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
                              Text(
                                contacts[index].name,
                                maxLines: 1,
                              ),
                              Container(
                                width: 160,
                                child: Text(
                                  contacts[index].latestMessage.body,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    fontWeight: FontWeight.w100,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              contacts[index].newMessageCount > 0
                                  ? Badge.count(
                                      count: contacts[index].newMessageCount,
                                      backgroundColor: Colors.green,
                                    )
                                  : const SizedBox.shrink(),
                              const SizedBox(width: 8.0),
                              Text(contacts[index].getLatestTime,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w100,
                                      fontSize: 16.0)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                });
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => MessagesNewScreen()));
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.message),
      ),
    );
  }
}
