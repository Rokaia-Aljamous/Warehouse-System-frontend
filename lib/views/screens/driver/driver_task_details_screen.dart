import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/models/driver_task_model.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/screens/driver/map_screen.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';

class DriverTaskDetailsScreen extends StatefulWidget {
  final DriverTask task;

  const DriverTaskDetailsScreen({super.key, required this.task});

  @override
  State<DriverTaskDetailsScreen> createState() =>
      _DriverTaskDetailsScreenState();
}

class _DriverTaskDetailsScreenState extends State<DriverTaskDetailsScreen> {
  late Future<DriverTask?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = context.read<DriverController>().fetchTaskDetails(
      widget.task.id,
    );
  }

  void _reload() {
    setState(() {
      _detailsFuture = context.read<DriverController>().fetchTaskDetails(
        widget.task.id,
      );
    });
  }

  Future<void> _start(DriverTask task) async {
    final controller = context.read<DriverController>();
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: MapScreen(task: task),
        ),
      ),
    );

    if (completed == true) {
      await controller.refreshAll();
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          ReceivingTopHeader(
            height: MediaQuery.of(context).size.height * 0.22,
            title: 'Task Details',
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -42),
              child: FutureBuilder<DriverTask?>(
                future: _detailsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final task = snapshot.data ?? widget.task;
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      children: [
                        _DetailsCard(task: task),
                        if (task.items.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Returned Products',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...task.items.map(
                            (item) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Color(0xFFF3A523),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(item.name)),
                                  Text('x${item.quantity}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (!task.isCompleted)
                          SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: task.hasCoordinates
                                  ? () => _start(task)
                                  : null,
                              icon: const Icon(Icons.navigation_outlined),
                              label: Text(
                                task.hasCoordinates
                                    ? 'Start'
                                    : 'Destination coordinates unavailable',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  static const Color gold = Color(0xFFF3A523);
  final DriverTask task;

  const _DetailsCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.referenceLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (task.isCompleted ? AppColors.greenLight : gold)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  task.isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: task.isCompleted ? AppColors.greenLight : gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _row(Icons.task_alt, 'Task', task.typeLabel),
          if (task.customerName != null)
            _row(Icons.person_outline, 'Customer', task.customerName!),
          if (task.customerPhone != null)
            _row(Icons.phone_outlined, 'Phone', task.customerPhone!),
          _row(Icons.location_on_outlined, 'Destination', task.displayLocation),
          if (task.deliveryRegion != null)
            _row(Icons.map_outlined, 'Region', task.deliveryRegion!),
          if (task.itemsCount != null)
            _row(
              Icons.inventory_2_outlined,
              'Items',
              task.itemsCount.toString(),
            ),
          if (task.totalPrice != null)
            _row(
              Icons.payments_outlined,
              'Total',
              task.totalPrice!.toStringAsFixed(2),
            ),
          if (task.returnReason != null)
            _row(Icons.reply_outlined, 'Return reason', task.returnReason!),
          if (task.fromWarehouseName != null)
            _row(
              Icons.warehouse_outlined,
              'From warehouse',
              '${task.fromWarehouseName!}${task.fromWarehouseLocation == null ? '' : ' — ${task.fromWarehouseLocation}'}',
            ),
          if (task.toWarehouseName != null)
            _row(
              Icons.flag_outlined,
              'To warehouse',
              '${task.toWarehouseName!}${task.toWarehouseLocation == null ? '' : ' — ${task.toWarehouseLocation}'}',
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
