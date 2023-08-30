import 'dart:convert';
import 'dart:io';

import 'package:cipher_chat/Screens/Messages/messages_list.dart';
import 'package:cipher_chat/globalState/global_state.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../globalState/messages.dart';
import '../../globalState/user.dart';

class MessagesNewScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MessageNewScreenState();
  }
}

class _MessageNewScreenState extends State<MessagesNewScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<Contact>>? _searchFuture;

  Future<List<Contact>> _searchContact(String query) async {
    if (query == '') {
      throw Exception('Empty Input!');
    }
    final User user = Provider.of<GlobalState>(context, listen: false).user!;

    final String username = user.username;
    final String serverhost = user.serverHost;
    final String token = user.token;

    var res = await http.get(
      Uri.parse('$serverhost/user/search?username=$query'),
      headers: <String, String>{
        HttpHeaders.authorizationHeader: 'Basic $token',
      },
    );

    if (res.statusCode == 200) {
      final resBody = jsonDecode(res.body);
      //debugPrint(resBody);

      final List<Contact> resList = <Contact>[];

      if (resBody == null) {
        return resList;
      }

      for (var con in resBody) {
        if (con['id'] == username) {
          continue;
        }
        final newCon = Contact(
            name: con['id'], publickey: con['public_key'], profilePic: '');
        resList.add(newCon);
      }

      return resList;
    } else if (res.statusCode == 400) {
      var resBody = jsonDecode(res.body);
      throw Exception(resBody['error']);
    } else if (res.statusCode == 401) {
      tokenExpiredLogoutHandler(
          context, Provider.of<GlobalState>(context, listen: false));
      return <Contact>[];
    } else {
      throw Exception('Server responded with status code ${res.statusCode}');
    }
  }

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
                        onPressed: () {
                          final searchFuture =
                              _searchContact(_searchController.text);
                          setState(() {
                            _searchFuture = searchFuture;
                          });
                        },
                        icon: const Icon(Icons.search)))
              ],
            ),
            const SizedBox(height: 8.0),
            Expanded(
              // padding:
              //     const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: _searchFuture == null
                  ? const Center(child: Text('Not found'))
                  : FutureBuilder(
                      future: _searchFuture,
                      builder: (BuildContext context,
                          AsyncSnapshot<List<Contact>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Text('${snapshot.error}')));
                          } else {
                            final List<Contact> results = snapshot.data!;

                            if (results.isEmpty) {
                              return const Center(child: Text('Not found'));
                            }

                            return ListView.builder(
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  return InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (context) {
                                          return MessagesListScreen(
                                              contact: results[index],
                                              isNew: true);
                                        }),
                                      );
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
                                                color: Colors.white,
                                                size: 40.0),
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
                                });
                          }
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      }),
            )
          ],
        ),
      ),
    );
  }
}
