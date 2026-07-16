// lib/views/screens/warehouse/archive_tab_content.dart

import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

class ArchiveTabContent extends StatelessWidget {
  const ArchiveTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: 2,
      itemBuilder: (context, index) {
        final isMyOrder = index == 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.navy.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Destrution',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(height: 8),
              _buildRow(Icons.inventory_2_outlined, 'Shipment Name'),
              _buildRow(Icons.shopping_cart_outlined, 'Qty: 1 Units'),
              _buildRow(Icons.warning_amber_rounded, 'Cause of damage'),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isMyOrder ? 'My Order' : 'Admin',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isMyOrder ? AppColors.navy : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
