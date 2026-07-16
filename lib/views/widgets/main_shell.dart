// lib/views/widgets/main_shell.dart

import 'package:flutter/material.dart';
import 'package:stock_app/views/screens/common/edit_profile_screen.dart';
import 'package:stock_app/views/screens/common/profile_screen.dart';
import 'package:stock_app/views/screens/warehouse/MyTasksScreen.dart';
import 'package:stock_app/views/screens/warehouse/warehouse_home.dart';
import 'package:stock_app/views/widgets/custom_bottom_nav.dart';

// ============================================================
// الـ Main Shell — الهيكل الرئيسي للتطبيق بعد تسجيل الدخول
// ============================================================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const WarehouseHome(), // index 0 — Home
      const MyTaskScreen(), // index 1 — My Tasks
      ProfileScreen(onEditProfile: () => _changePage(3)), // index 2 — Profile
      EditProfileScreen(onBack: () => _changePage(2)), // index 3 — Edit Profile
    ];
  }

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      // إذا كان المستخدم في صفحة Edit (3) نُفعّل أيقونة Profile (2)
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex == 3 ? 2 : _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
