import 'package:flutter/material.dart';

class ForcaPainter extends CustomPainter {
  final int tentativas;

  ForcaPainter(this.tentativas);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    // Base
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.8),
      Offset(size.width * 0.4, size.height * 0.8),
      paint,
    );

    // Poste vertical
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.3, size.height * 0.2),
      paint,
    );

    // Topo
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.2),
      paint,
    );

    // Corda
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.3),
      paint,
    );

    if (tentativas < 6) {
      // Cabeça
      canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.35),
        size.width * 0.05,
        paint,
      );
    }

    if (tentativas < 5) {
      // Corpo
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.4),
        Offset(size.width * 0.6, size.height * 0.6),
        paint,
      );
    }

    if (tentativas < 4) {
      // Braço esquerdo
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.45),
        Offset(size.width * 0.5, size.height * 0.5),
        paint,
      );
    }

    if (tentativas < 3) {
      // Braço direito
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.45),
        Offset(size.width * 0.7, size.height * 0.5),
        paint,
      );
    }

    if (tentativas < 2) {
      // Perna esquerda
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.6),
        Offset(size.width * 0.5, size.height * 0.7),
        paint,
      );
    }

    if (tentativas < 1) {
      // Perna direita
      canvas.drawLine(
        Offset(size.width * 0.6, size.height * 0.6),
        Offset(size.width * 0.7, size.height * 0.7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ForcaPainter oldDelegate) =>
      tentativas != oldDelegate.tentativas;
}
