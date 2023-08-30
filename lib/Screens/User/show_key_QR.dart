import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowKeyQRScreen extends StatefulWidget {
  final String _publicKey;
  final String _username;

  ShowKeyQRScreen(this._username, this._publicKey);

  @override
  State<StatefulWidget> createState() {
    return ShowKeyQRState();
  }
}

class ShowKeyQRState extends State<ShowKeyQRScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Show Key QR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QrImageView(
                data: widget._publicKey,
                size: MediaQuery.of(context).size.width * 0.75,
              ),
              const SizedBox(
                height: 16.0,
              ),
              Text('Username: ${widget._username}'),
            ],
          ),
        ),
      ),
    );
  }
}
