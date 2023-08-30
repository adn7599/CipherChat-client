import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class VerifyKeyQRScreen extends StatefulWidget {
  final String conName;
  final String conPublicKey;

  VerifyKeyQRScreen({required this.conName, required this.conPublicKey});
  @override
  State<StatefulWidget> createState() {
    return VerifyKeyQRState();
  }
}

class VerifyKeyQRState extends State<VerifyKeyQRScreen> {
  MobileScannerController? _controller =
      MobileScannerController(detectionSpeed: DetectionSpeed.normal);

  bool isVerified = false;
  bool isVerificationDone = false;

  void _verifyContact(String conPublicKeyFromQR) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Verify QR'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: isVerificationDone
                  ? isVerified
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 24,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8.0),
                            Text('Verified',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 24,
                                ))
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 24, color: Colors.red),
                            SizedBox(width: 8.0),
                            Text(
                              'Not Verified',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 24,
                              ),
                            )
                          ],
                        )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('verify ${widget.conName}'),
                        const SizedBox(
                          height: 16.0,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: MobileScanner(
                              controller: _controller,
                              fit: BoxFit.contain,
                              onDetect: (capture) {
                                final List<Barcode> barcodes = capture.barcodes;
                                final barcode = barcodes[0];
                                // debugPrint('Found QRCode value: ${barcode.rawValue}');
                                final conPubKeyFromQR = barcode.rawValue!;
                                debugPrint(
                                    'Found QRCode value: $conPubKeyFromQR');
                                _controller?.dispose();
                                _controller = null;
                                setState(() {
                                  if (conPubKeyFromQR == widget.conPublicKey) {
                                    isVerified = true;
                                  } else {
                                    isVerified = false;
                                  }
                                  isVerificationDone = true;
                                });
                              }),
                        ),
                      ],
                    ),
            )));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
