// lib/views/screens/warehouse/disposal_details_screen.dart
//
// تفاصيل طلب إتلاف واحد (طلب بعته العامل بنفسه) —
//   GET /workers/disposals/{id}
//
// كل الحقول المعروضة جايه حرفياً من DestructionController.currentDisposal
// (Disposal model) بدون أي تلوين/تصنيف مبني على تخمين — بس عرض الـ raw
// status متل ما إجا من الباك.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/destruction_controller.dart';
import '../../../utils/constants.dart';
import '../../../views/widgets/auth_widgets.dart';

class DisposalDetailsScreen extends StatefulWidget {
  final int disposalId;
  const DisposalDetailsScreen({super.key, required this.disposalId});

  @override
  State<DisposalDetailsScreen> createState() => _DisposalDetailsScreenState();
}

class _DisposalDetailsScreenState extends State<DisposalDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DestructionController>().fetchDisposalDetails(widget.disposalId);
    });
  }

  @override
  void dispose() {
    context.read<DestructionController>().clearCurrentDisposal();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          ReceivingTopHeader(
            height: screenHeight * 0.22,
            title: 'Request Details',
          ),
          Expanded(
            child: Consumer<DestructionController>(
              builder: (context, controller, _) {
                if (controller.isLoadingDetails && controller.currentDisposal == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.detailsError != null && controller.currentDisposal == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                          const SizedBox(height: 12),
                          Text(controller.detailsError!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                controller.fetchDisposalDetails(widget.disposalId),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final d = controller.currentDisposal;
                if (d == null) return const SizedBox.shrink();

                return Transform.translate(
                  offset: const Offset(0, -40),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.navy.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('ID', '#${d.id}'),
                          _row('Product', d.productName ?? '-'),
                          _row('Barcode', d.barcode ?? '-'),
                          _row('Quantity', '${d.quantity}'),
                          _row('Damage reason', d.damageReason ?? '-'),
                          _row('Status', d.status ?? '-'),
                          _row('Shipment', d.shipmentName ?? '-'),
                          _row(
                            'Created',
                            d.createdAt != null
                                ? '${d.createdAt!.day}/${d.createdAt!.month}/${d.createdAt!.year}'
                                : '-',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}