import 'package:cipher_chat/Screens/User/verify_key_QR.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../globalState/global_state.dart';
import '../../globalState/messages.dart';

class MessagesListScreen extends StatefulWidget {
  final Contact contact;
  final bool isNew;

  MessagesListScreen({required this.contact, required this.isNew});

  @override
  State<StatefulWidget> createState() {
    return MessageListState();
  }
}

class MessageListState extends State<MessagesListScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollCont = ScrollController();
  bool _isNew = false;
  bool _sentFirstMsg = false;

  Future<void> _sendMessage(GlobalState gs, String msg) async {
    if (_isNew) {
      debugPrint('Sending messsage | new contact');
      if (!_sentFirstMsg) {
        debugPrint('Sending First messsage | new contact');
        await gs.addContact(widget.contact);
        _sentFirstMsg = true;
      }
      await gs.sendMessage(
          widget.contact, Message.New(type: MessageType.Sent, body: msg));
    } else {
      await gs.sendMessage(
          widget.contact, Message.New(type: MessageType.Sent, body: msg));
    }
  }

  @override
  void initState() {
    super.initState();
    //run once when layout build is complete (only for the first time)
    // _scrollCont.addListener(() {
    //   _scrollListener();
    // });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCont.jumpTo(_scrollCont.position.maxScrollExtent);
    });
  }

  // void _scrollListener() {
  //   debugPrint('Inside scroll listener');
  //   if (_scrollCont.position.pixels != _scrollCont.position.maxScrollExtent) {
  //     debugPrint('scroll | Not down');
  //   }else{
  //     debugPrint('scroll | Completely down');
  //   }
  // }

  void _handlePopUpMenu(String value) {
    switch (value) {
      case 'Verify QR':
        // debugPrint('selected Verfiy QR');
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => VerifyKeyQRScreen(
                  conName: widget.contact.name,
                  conPublicKey: widget.contact.publickey,
                )));
        break;
      default:
        debugPrint('Invalid option selected');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('isNew : ${widget.isNew}');
    return Scaffold(
      appBar: AppBar(
          title: Row(children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20.0,
              child: Icon(Icons.person, color: Colors.black, size: 24.0),
            ),
            const SizedBox(width: 12.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contact.name),
                // const Text(
                //   'Online',
                //   style: TextStyle(fontSize: 12.0),
                // ),
              ],
            ),
          ]),
          actions: [
            PopupMenuButton(
                onSelected: _handlePopUpMenu,
                itemBuilder: (BuildContext context) {
                  return ['Verify QR'].map((String choice) {
                    return PopupMenuItem(value: choice, child: Text(choice));
                  }).toList();
                }),
          ]),
      body: Column(
        children: [
          Expanded(
            child: Consumer<GlobalState>(
              builder: (context, gs, child) {
                final contacts = gs.contacts!;
                Contact contact;
                int foundIndex = 0;
                if (widget.isNew) {
                  foundIndex = contacts.indexWhere(
                      (element) => element.name == widget.contact.name);
                  if (foundIndex == -1) {
                    //not found, actually new
                    debugPrint('Actually new');
                    _isNew = true;
                  }
                }
                if (_isNew) {
                  contact = widget.contact;
                } else {
                  if (widget.isNew) {
                    contact = contacts[foundIndex];
                  } else {
                    contact = contacts[contacts
                        .indexWhere((con) => con.name == widget.contact.name)];
                  }
                }

                return ListView.builder(
                    controller: _scrollCont,
                    itemCount: contact.messages.length,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.only(
                            left: 14, right: 14, top: 10, bottom: 10),
                        child: Align(
                          alignment: (contact.messages[index].type ==
                                  MessageType.Received
                              ? Alignment.topLeft
                              : Alignment.topRight),
                          child: Container(
                              margin: contact.messages[index].type ==
                                      MessageType.Received
                                  ? const EdgeInsets.only(right: 100.0)
                                  : const EdgeInsets.only(left: 100.0),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: (contact.messages[index].type ==
                                          MessageType.Received)
                                      ? Colors.grey.shade200
                                      : Colors.black),
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                contact.messages[index].body,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: contact.messages[index].type ==
                                            MessageType.Received
                                        ? Colors.black
                                        : Colors.white),
                              )),
                        ),
                      );
                    });
              },
            ),
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
                      maxLines: null),
                ),
                IconButton(
                  onPressed: () {
                    if (_messageController.text == '') {
                      return;
                    }
                    _sendMessage(
                        Provider.of<GlobalState>(context, listen: false),
                        _messageController.text);

                    _messageController.text = '';

                    //Done because maxScrollExtent was getting old value before new message so was only scrolling to second last message
                    Future.delayed(const Duration(milliseconds: 350), () {
                      _scrollCont.animateTo(
                          _scrollCont.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 100),
                          curve: Curves.bounceIn);
                    });
                  },
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
