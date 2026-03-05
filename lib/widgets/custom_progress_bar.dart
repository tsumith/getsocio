import 'package:flutter/cupertino.dart';

class RoundedRectProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  RoundedRectProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create the rounded rectangle path
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);

    // Calculate the partial path based on progress
    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0.0, pathMetrics.length * progress);

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(RoundedRectProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}