import 'package:flutter/material.dart';

class FormInput extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final bool isHidden;
  const FormInput(
      {super.key,
      required this.title,
      required this.controller,
      this.isHidden = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: title),
        obscureText: isHidden,
      ),
    );
  }
}
