import 'dart:math';
import 'package:flutter/material.dart';

class WiggleSlider extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final bool isPlaying;
  final double phase;
  final ValueChanged<double> onScrub;

  const WiggleSlider({
    super.key,
    required this.value,
    required this.isPlaying,
    required this.phase,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _processTouch(details.localPosition, width),
          onTapDown: (details) => _processTouch(details.localPosition, width),
          child: CustomPaint(
            size: Size(width, 44),
            painter: WavySliderPainter(
              progress: value,
              phase: phase,
              isPlaying: isPlaying,
              screenWidth: width,
            ),
          ),
        );
      },
    );
  }

  void _processTouch(Offset position, double width) {
    final double percent = (position.dx / width).clamp(0.0, 1.0);
    onScrub(percent);
  }
}

class WavySliderPainter extends CustomPainter {
  final double progress;
  final double phase;
  final bool isPlaying;
  final double screenWidth;

  WavySliderPainter({
    required this.progress,
    required this.phase,
    required this.isPlaying,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double amplitude = isPlaying ? (size.height * 0.001).clamp(2.5, 6.0) : 0.0;
    final double wavelength = screenWidth / 10;
    final double centerY = size.height / 2;
    final double activeWidth = size.width * progress;

    final activePaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = (screenWidth > 600) ? 4.5 : 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = (screenWidth > 600) ? 4.5 : 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw Active Wavy Path
    final path = Path();
    path.moveTo(0, centerY);
    for (double x = 0; x <= activeWidth; x += 2) {
      double y = centerY + amplitude * sin((x / wavelength) * 2 * pi + phase);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, activePaint);

    // 2. Draw Inactive Flat Path
    canvas.drawLine(
      Offset(activeWidth, centerY),
      Offset(size.width, centerY),
      inactivePaint,
    );

    // 3. Draw the Rotating Squircle (Thumb)
    if (isPlaying || progress > 0) {
      // Calculate current vertical position of the wave end
      final double thumbY = centerY + (amplitude * sin((activeWidth / wavelength) * 2 * pi + phase));

      canvas.save();
      // Move the canvas origin to the thumb position
      canvas.translate(activeWidth, thumbY);

      // Rotate based on phase (2 * pi is one full rotation)
      // If you want it to spin faster/slower, multiply phase by a factor
      canvas.rotate(phase);

      final thumbSize = (screenWidth > 600) ? 14.0 : 11.0;
      final squircleRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: thumbSize, height: thumbSize),
        Radius.circular(thumbSize * 0.3),
      );

      final thumbPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawRRect(squircleRect, thumbPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant WavySliderPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying;
  }
}