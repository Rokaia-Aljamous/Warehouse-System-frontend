// lib/views/screens/warehouse/MyTasksScreen.dart

import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_header_widgets.dart';

// MyTaskScreen لا يعرض الـ BottomNav بشكل مستقل —
// التنقل يتم من خلال MainShell الموجود في main_shell.dart
class MyTaskScreen extends StatefulWidget {
  const MyTaskScreen({super.key});

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen> {
  bool isPendingSelected = true;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          // 1. الهيدر
          ReceivingTopHeader(height: screenHeight * 0.22, title: 'My Tasks'),

          Transform.translate(
            offset: const Offset(0, -50),
            child: Column(
              children: [
                // 2. التبويب التفاعلي (Pending / Completed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.navy.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('Pending', true),
                        _buildTabButton('Completed', false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. قائمة المهام
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _TaskCard(isPending: isPendingSelected);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isPending) {
    bool isSelected = isPendingSelected == isPending;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isPendingSelected = isPending),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF3EDE4) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
              decoration: isSelected
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

// كرت المهمة
class _TaskCard extends StatelessWidget {
  final bool isPending;
  const _TaskCard({required this.isPending});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.pending_actions : Icons.task_alt,
            color: AppColors.navy,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order # 88',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  'Customer name',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const Text('Items: 4', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          Text(
            isPending ? 'Due: 3 hours' : '13/2/2026',
            style: TextStyle(
              color: AppColors.greenLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
