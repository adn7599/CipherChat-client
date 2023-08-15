import 'package:flutter/material.dart';

class FormButton extends StatelessWidget {
  final String title;
  final void Function() onPress;

  const FormButton({super.key, required this.title, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      child: ElevatedButton(
        style: const ButtonStyle(
            padding:
                MaterialStatePropertyAll(EdgeInsets.symmetric(vertical: 16.0))),
        onPressed: () {
          onPress();
        },
        child: Text(
          title,
        ),
      ),
    );
  }
}
