import 'package:flutter/material.dart';

class SelectionLinePainter extends CustomPainter {
  final List<String> selectedCellsOrder;
  final double cellSize;
  final int gridSize;

  SelectionLinePainter({
    required this.selectedCellsOrder,
    required this.cellSize,
    required this.gridSize,
  });

  Color _interpolateColor(Color a, Color b, double t) {
    return Color.fromARGB(
      (a.alpha + (b.alpha - a.alpha) * t).round(),
      (a.red + (b.red - a.red) * t).round(),
      (a.green + (b.green - a.green) * t).round(),
      (a.blue + (b.blue - b.blue) * t).round(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedCellsOrder.isEmpty) return;

    const maxWordLength = 16;
    final startColor = Colors.green;
    final endColor = Colors.purple;

    final paint = Paint()
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw background paths first
    final backgroundPaint = Paint()
      ..strokeWidth = 60
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..color = Colors.white; // White background for contrast

    if (selectedCellsOrder.length == 1) {
      // For a single selected letter, draw a circle
      final current = selectedCellsOrder[0].split(',').map(int.parse).toList();
      final centerX = (current[1] + 0.5) * cellSize;
      final centerY = (current[0] + 0.5) * cellSize;

      // Draw white background circle first
      canvas.drawCircle(
        Offset(centerX, centerY),
        5.0, // Small radius for the dot
        backgroundPaint,
      );

      // Draw colored circle
      paint.color = startColor;
      canvas.drawCircle(
        Offset(centerX, centerY),
        5.0, // Small radius for the dot
        paint,
      );
      return;
    }

    // For multiple selected letters, draw lines
    for (int i = 0; i < selectedCellsOrder.length - 1; i++) {
      final current = selectedCellsOrder[i].split(',').map(int.parse).toList();
      final next = selectedCellsOrder[i + 1].split(',').map(int.parse).toList();

      final startX = (current[1] + 0.5) * cellSize;
      final startY = (current[0] + 0.5) * cellSize;
      final endX = (next[1] + 0.5) * cellSize;
      final endY = (next[0] + 0.5) * cellSize;

      // Draw white background line first
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        backgroundPaint,
      );

      // Always progress the color regardless of direction
      final progress = i / (maxWordLength - 1);
      paint.color = _interpolateColor(startColor, endColor, progress);

      // Draw the colored line
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(SelectionLinePainter oldDelegate) {
    return oldDelegate.selectedCellsOrder != selectedCellsOrder;
  }
}
