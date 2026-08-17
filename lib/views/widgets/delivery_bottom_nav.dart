// lib/views/widgets/delivery_bottom_nav.dart

import 'package:flutter/material.dart';

class DeliveryBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DeliveryBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 40;
    final double tabWidth = width / 4;
    final double targetCenterX = (currentIndex * tabWidth) + (tabWidth / 2);

    return Container(
      height: 75,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: targetCenterX, end: targetCenterX),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (context, animatedX, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, 75),
                painter: _DeliveryNavPainter(
                  centerX: animatedX,
                  backgroundColor: const Color(0xFF1F3151),
                ),
              ),
              Positioned(
                left: animatedX - 8,
                top: -6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3A523),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_filled),
                    _buildNavItem(1, Icons.person_outline),
                    _buildNavItem(2, Icons.task_alt_outlined),
                    _buildNavItem(3, Icons.reply_rounded),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: currentIndex == index ? const Color(0xFFF3A523) : Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

class _DeliveryNavPainter extends CustomPainter {
  final double centerX;
  final Color backgroundColor;

  _DeliveryNavPainter({required this.centerX, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = backgroundColor;
    final path = Path();

    const notchWidth = 17.0;
    const notchDepth = 14.0;
    const borderRadius = 30.0;

    path.moveTo(borderRadius, 0);
    path.lineTo(centerX - notchWidth - 8, 0);
    path.cubicTo(
      centerX - notchWidth,
      0,
      centerX - (notchWidth * 0.5),
      notchDepth,
      centerX,
      notchDepth,
    );
    path.cubicTo(
      centerX + (notchWidth * 0.5),
      notchDepth,
      centerX + notchWidth,
      0,
      centerX + notchWidth + 8,
      0,
    );
    path.lineTo(size.width - borderRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, borderRadius);
    path.lineTo(size.width, size.height - borderRadius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - borderRadius,
      size.height,
    );
    path.lineTo(borderRadius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - borderRadius);
    path.lineTo(0, borderRadius);
    path.quadraticBezierTo(0, 0, borderRadius, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DeliveryNavPainter oldDelegate) =>
      oldDelegate.centerX != centerX ||
      oldDelegate.backgroundColor != backgroundColor;
}
