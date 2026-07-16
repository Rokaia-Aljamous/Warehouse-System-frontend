// lib/views/widgets/custom_bottom_nav.dart

import 'package:flutter/material.dart';

// ============================================================
// شريط التنقل السفلي المخصص
// ============================================================
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 40;
    final double tabWidth = width / 3;
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
              // 1. الشكل الخلفي مع التقوس
              CustomPaint(
                size: Size(width, 75),
                painter: _BottomNavPainter(
                  centerX: animatedX,
                  backgroundColor: const Color(0xFF1F3151),
                ),
              ),
              // 2. الكرة المتحركة فوق الأيقونة النشطة
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
              // 3. الأيقونات (ثابتة)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_filled),
                    _buildNavItem(1, Icons.fact_check_outlined),
                    _buildNavItem(2, Icons.person_outline),
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
      child: Icon(
        icon,
        color: currentIndex == index ? const Color(0xFFF3A523) : Colors.white,
        size: 28,
      ),
    );
  }
}

class _BottomNavPainter extends CustomPainter {
  final double centerX;
  final Color backgroundColor;

  _BottomNavPainter({required this.centerX, required this.backgroundColor});

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
  bool shouldRepaint(covariant _BottomNavPainter oldDelegate) =>
      oldDelegate.centerX != centerX ||
      oldDelegate.backgroundColor != backgroundColor;
}
