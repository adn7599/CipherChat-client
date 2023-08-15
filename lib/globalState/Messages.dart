import 'package:uuid/uuid.dart';

class Message {
  late String uuid;
  late DateTime time;
  String sender;
  String receiver;

  String body;

  Message({required this.sender, required this.receiver, required this.body}) {
    this.time = DateTime.now();
    this.uuid = Uuid().v4();
  }
}

class Contact {
  String name;
  String profilePic = '';

  List<Message> messages = <Message>[
    Message(sender: 'me', receiver: 'you', body: 'text1'),
    Message(sender: 'me', receiver: 'you', body: 'text2'),
    Message(sender: 'me', receiver: 'you', body: 'text3'),
    Message(sender: 'you', receiver: 'me', body: 'text4'),
    Message(sender: 'you', receiver: 'me', body: 'text4'),
    Message(sender: 'me', receiver: 'you', body: 'text4'),
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
