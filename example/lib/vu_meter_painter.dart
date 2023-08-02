import 'package:flutter/material.dart';

class VuMeterPainter extends CustomPainter {
  final double vuValue;
  final Color fillColor;

  VuMeterPainter(this.vuValue, this.fillColor);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.grey);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * vuValue, size.height),
        Paint()..color = fillColor);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
