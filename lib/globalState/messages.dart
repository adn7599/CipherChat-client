class Message {
  late DateTime time;
  MessageType type;

  String body;

  Message({required this.type, required this.body, required this.time}) {}

  Message.New({required this.type, required this.body}) {
    time = DateTime.now();
  }

  String get timeString {
    final now = DateTime.now();
    final hour = time.hour % 12;
    final ampm = time.hour > 12 ? 'pm' : 'am';

    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      //today
      return "${hour % 12}:${time.minute} $ampm";
    } else {
      return "${time.day}-${time.month}-${time.year} ${hour % 12}:${time.minute} $ampm";
    }
  }
}

enum MessageType { Sent, Received }

class Contact {
  String name;
  String profilePic = '';
  String publickey;
  int newMessageCount;

  // List<Message> messages = <Message>[
  //   Message.New(type: 'sent', body: 'text1'),
  //   Message.New(type: 'sent', body: 'text2'),
  //   Message.New(type: 'received', body: 'text2'),
  //   Message.New(type: 'received', body: 'text3'),
  //   Message.New(type: 'sent', body: 'text4'),
  //   Message.New(type: 'received', body: 'text5'),
  //   Message.New(type: 'received', body: 'text5'),
  //   Message.New(type: 'received', body: 'text5'),
  //   Message.New(type: 'received', body: 'text5'),
  //   Message.New(type: 'received', body: 'lorem ipsum'),
  // ];

  List<Message> messages = <Message>[];

  Contact(
      {required this.name,
      required this.profilePic,
      required this.publickey,
      required this.newMessageCount});

  Message get latestMessage {
    return messages.last;
  }

  String get getLatestTime {
    return latestMessage.timeString;
  }
}
