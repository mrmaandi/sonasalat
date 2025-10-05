import 'package:flutter/material.dart';

class AnimatedSegmentPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;

  AnimatedSegmentPainter({
    required this.start,
    required this.end,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 60.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final currentEnd = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );
    canvas.drawLine(start, currentEnd, paint);
  }

  @override
  bool shouldRepaint(AnimatedSegmentPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.start != start ||
        oldDelegate.end != end;
  }
}
