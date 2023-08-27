class Message {
  late DateTime time;
  MessageType type;

  String body;

  Message({required this.type, required this.body, required this.time}) {}

  Message.New({required this.type, required this.body}) {
    time = DateTime.now();
  }
}

enum MessageType { Sent, Received }

class Contact {
  String name;
  String profilePic = '';
  String publickey;

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
      {required this.name, required this.profilePic, required this.publickey});

  Message get latestMessage {
    return messages.last;
  }

  String get getLatestTime {
    var time = latestMessage.time;
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
