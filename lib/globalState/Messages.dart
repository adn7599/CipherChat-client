import 'package:uuid/uuid.dart';

class Message {
  late DateTime time;
  String type;

  String body;

  Message({required this.type, required this.body, required this.time}) {}

  Message.New({required this.type, required this.body}) {
    time = DateTime.now();
  }
}

class Contact {
  String name;
  String profilePic = '';
  String publickey;

  List<Message> messages = <Message>[
    Message.New(type: 'sent', body: 'text1'),
    Message.New(type: 'sent', body: 'text2'),
    Message.New(type: 'received', body: 'text2'),
    Message.New(type: 'received', body: 'text3'),
    Message.New(type: 'sent', body: 'text4'),
    Message.New(type: 'received', body: 'text5'),
    Message.New(type: 'received', body: 'text5'),
    Message.New(type: 'received', body: 'text5'),
    Message.New(type: 'received', body: 'text5'),
    Message.New(type: 'received', body: 'lorem ipsum'),
  ];

  Contact(
      {required this.name, required this.profilePic, required this.publickey});

  Message getLatestMessage() {
    return messages.last;
  }

  String getLatestTime() {
    var time = getLatestMessage().time;
    var now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      //today
      return "${time.hour}:${time.minute}";
    } else {
      return "${time.day}-${time.month}-${time.year} ${time.hour}:${time.minute}";
    }
  }
}
