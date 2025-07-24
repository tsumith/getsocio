import 'package:flutter/material.dart';

class ShellPlayer extends StatelessWidget {
  const ShellPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10,vertical:0),
      height: 60,
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
