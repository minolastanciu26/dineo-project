import 'package:flutter/material.dart';

class SemicircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width * 0.5, 0);
    path.quadraticBezierTo(size.width, size.height * 0.5, size.width * 0.5, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}