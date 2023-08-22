import 'package:flutter/material.dart';

import '../../globalState/messages.dart';

class MessagesNewScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MessageNewScreenState();
  }
}

class _MessageNewScreenState extends State<MessagesNewScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Contact> results = [
    Contact(name: 'advait', profilePic: '', publickey: ''),
    Contact(name: 'naik', profilePic: '', publickey: ''),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration:
                          const InputDecoration(hintText: 'Search Users'),
                    ),
                  ),
                ),
                Container(
                    padding: const EdgeInsets.all(4.0),
                    child: IconButton(
                        onPressed: () {}, icon: const Icon(Icons.search)))
              ],
            ),
            const SizedBox(height: 8.0),
            results.isEmpty
                ? const Expanded(
                    child: Center(child: Text('Not found')),
                  )
                : Expanded(
                    child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/messages',
                                  arguments: results[index]);
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(results[index].name),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                  )
          ],
        ),
      ),
    );
  }
}
