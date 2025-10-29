import 'dart:math';
import 'dart:ui';

Path drawStar(Size size) {
  final halfWidth = size.width / 2;
  final degreesPerStep = 2 * pi / 5;
  final fullAngle = 2 * pi;

  final path = Path();
  path.moveTo(size.width, halfWidth);

  for (double step = 0; step < fullAngle; step += degreesPerStep) {
    path.lineTo(halfWidth + halfWidth * cos(step), halfWidth + halfWidth * sin(step));
    path.lineTo(
      halfWidth + halfWidth / 2.5 * cos(step + degreesPerStep / 2),
      halfWidth + halfWidth / 2.5 * sin(step + degreesPerStep / 2),
    );
  }
  path.close();
  return path;
}
