import 'package:flutter/material.dart';
import 'package:stock_app/views/screens/warehouse/ReceivingScreen.dart';
import 'package:stock_app/views/screens/warehouse/PreparingScreen.dart';
import 'package:stock_app/views/screens/warehouse/RecoveryScreen.dart';
import 'package:stock_app/views/screens/warehouse/DestructionScreen.dart';
import 'package:stock_app/views/screens/common/details_screen.dart';
import 'package:stock_app/views/screens/common/notification_screen.dart';
import '../../../utils/constants.dart';

class WarehouseHome extends StatelessWidget {
  const WarehouseHome({super.key});

  static const List<_HomeItem> _items = [
    _HomeItem(label: 'Processing', icon: Icons.inventory_2_outlined),
    _HomeItem(label: 'Receiving', icon: Icons.move_to_inbox_outlined),
    _HomeItem(label: 'Recovery', icon: Icons.refresh_rounded),
    _HomeItem(label: 'Destruction', icon: Icons.delete_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.welcomeGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. الـ AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر الإعدادات - يفتح التفاصيل كـ BottomSheet
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: const DetailsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.tune,
                        color: AppColors.navy,
                        size: 30,
                      ),
                    ),

                    const Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),

                    // زر الإشعارات
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.navy,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. العنوان
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi laila!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Good Morning',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. الشبكة
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.95,
                        ),
                    itemBuilder: (context, index) =>
                        _HomeCard(item: _items[index], index: index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// كلاس الكارد (كما هو في كودك الأصلي)
class _HomeCard extends StatelessWidget {
  final _HomeItem item;
  final int index;
  const _HomeCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    BorderRadius radius = (index == 0 || index == 3)
        ? const BorderRadius.only(
            topRight: Radius.circular(40),
            bottomLeft: Radius.circular(40),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          );

    return GestureDetector(
      onTap: () {
        Widget screen;
        switch (item.label) {
          case 'Processing':
            screen = const PreparingScreen();
            break;
          case 'Receiving':
            screen = const ReceivingScreen();
            break;
          case 'Recovery':
            screen = const RecoveryScreen();
            break;
          case 'Destruction':
            screen = const DestructionScreen();
            break;
          default:
            return;
        }
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 45, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              item.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeItem {
  final String label;
  final IconData icon;
  const _HomeItem({required this.label, required this.icon});
}
