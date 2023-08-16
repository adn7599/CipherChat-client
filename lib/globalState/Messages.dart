import 'package:uuid/uuid.dart';

class Message {
  late String uuid;
  late DateTime time;
  String type;

  String body;

  Message({required this.type, required this.body}) {
    this.time = DateTime.now();
    this.uuid = Uuid().v4();
  }
}

class Contact {
  String name;
  String profilePic = '';

  List<Message> messages = <Message>[
    Message(type: 'sent', body: 'text1'),
    Message(type: 'sent', body: 'text2'),
    Message(type: 'received', body: 'text2'),
    Message(type: 'received', body: 'text3'),
    Message(type: 'sent', body: 'text4'),
    Message(type: 'received', body: 'text5'),
    Message(type: 'received', body: 'text5'),
    Message(type: 'received', body: 'text5'),
    Message(type: 'received', body: 'text5'),
    Message(type: 'received', body: 'lorem ipsum'),
  ];

  Contact({required this.name, required this.profilePic});

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
