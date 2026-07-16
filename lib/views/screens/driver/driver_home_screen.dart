// lib/views/screens/warehouse/MyTasksScreen.dart

import 'package:flutter/material.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/widgets/delivery_bottom_nav.dart';
import 'package:stock_app/views/screens/driver/map_screen.dart';
// 🌟 منطق المصادقة مأخوذ من المشروع الأول (AuthService متاح لقراءة بيانات السائق المسجل)
import 'package:stock_app/services/auth_service.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  int _currentIndex = 0;

  // الصفحات
  final List<Widget> _pages = [const _HomeContent(), const MapScreen()];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: _currentIndex == 0
          ? Column(
              children: [
                _MyTasksHeader(
                  screenHeight: screenHeight,
                  screenWidth: screenWidth,
                ),
                Expanded(child: _pages[0]),
              ],
            )
          : _pages[_currentIndex],
      bottomNavigationBar: DeliveryBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

// ============================================================
// محتوى الهوم منفصل كـ Widget
// ============================================================
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '12',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 65,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.flag_outlined, color: Colors.orange, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Today's\nDestinations",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              const Text(
                '|',
                style: TextStyle(
                  fontSize: 60,
                  color: Colors.black12,
                  fontWeight: FontWeight.w100,
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 2 / 12,
                        strokeWidth: 20,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.navy,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '2/12',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Delivered',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.navy.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.person_outline, color: Colors.black54, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Customer Name:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(
                      Icons.location_on_outlined,
                      color: Colors.black54,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Location:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.navigation_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Start The Path',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'List Of Remaining Tasks',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          _buildTaskCard('Customer Name:', 'Order Status : Ready To Download'),
          const SizedBox(height: 12),
          _buildTaskCard(
            'Customer Name:',
            'Order Status : Waiting For Processing',
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String name, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// الهيدر
// ============================================================
class _MyTasksHeader extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;

  const _MyTasksHeader({required this.screenHeight, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final double headerHeight = screenHeight * 0.22;

    return SizedBox(
      width: double.infinity,
      height: headerHeight,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: headerHeight,
            color: AppColors.navy,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(double.infinity, headerHeight * 0.45),
              painter: _MyTasksWavePainter(waveColor: AppColors.beige),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white, size: 26),
                    onPressed: () {},
                  ),
                  const Expanded(
                    child: Text(
                      "Today's Summary",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.reply_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () {},
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyTasksWavePainter extends CustomPainter {
  final Color waveColor;
  _MyTasksWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = waveColor;
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(0, 0, size.width * 0.20, 0);
    path.lineTo(size.width * 0.85, 0);
    path.quadraticBezierTo(size.width, 0, size.width, -size.height * 0.85);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MyTasksWavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}
