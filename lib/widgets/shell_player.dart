import 'package:flutter/material.dart';

class ShellPlayer extends StatelessWidget {
  const ShellPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      height: 40,
      width: double.infinity,
      color: Colors.red,
      child: Center(
        child: Text(
          "anonymous player goes here",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
