// lib/views/screens/warehouse/recovery_screen.dart

import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';
import 'order_an_details.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  // متغير للتحكم في التبويب المختار
  bool isPendingSelected = true;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          // الهيدر
          ReceivingTopHeader(height: screenHeight * 0.22, title: 'Recovery'),

          // منطقة التبويبات
          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.greyLine.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // زر Pending
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => isPendingSelected = true),
                            child: _buildTabButton(
                              'Pending',
                              isPendingSelected,
                            ),
                          ),
                        ),
                        // زر Completed
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => isPendingSelected = false),
                            child: _buildTabButton(
                              'Completed',
                              !isPendingSelected,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // الخط الفاصل
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Divider(color: Colors.black12, thickness: 1),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // قائمة الكروت
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // التعديل هنا: لا يتم الانتقال إلا إذا كنا في تبويب Completed
                      if (!isPendingSelected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrderAnDetailsScreen(),
                          ),
                        );
                      }
                    },
                    child: _RecoveryCard(showDueTime: isPendingSelected),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // مساعد لبناء تصميم زر التبويب
  Widget _buildTabButton(String title, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF3EDE4) : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
          decoration: isSelected
              ? TextDecoration.underline
              : TextDecoration.none,
          decorationColor: AppColors.navy,
          decorationThickness: 1.5,
        ),
      ),
    );
  }
}

// كرت شحنة الاسترداد
class _RecoveryCard extends StatelessWidget {
  final bool showDueTime;
  const _RecoveryCard({required this.showDueTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withOpacity(0.6), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order # 88',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'customer name',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items: 4',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              Text(
                showDueTime ? 'Due: 2 hours' : '13/2/2026',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greenLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
