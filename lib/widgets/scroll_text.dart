import 'package:flutter/material.dart';
class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const ScrollingText({super.key, required this.text, required this.style});

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scroll());
  }

  void _scroll() async {
    while (_scrollController.hasClients) {
      await Future.delayed(const Duration(seconds: 2));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: widget.text.length * 200),
          curve: Curves.linear,
        );
      }
      await Future.delayed(const Duration(seconds: 1));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 1000), curve: Curves.easeOut);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Text(widget.text, style: widget.style),
    );
  }
}