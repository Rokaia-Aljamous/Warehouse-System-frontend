import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_app/controllers/driver_controller.dart';
import 'package:stock_app/models/driver_task_model.dart';
import 'package:stock_app/utils/constants.dart';
import 'package:stock_app/views/widgets/auth_widgets.dart';
import 'package:stock_app/views/widgets/driver_task_card.dart';

class DriverCompletedTasksScreen extends StatelessWidget {
  final ValueChanged<DriverTask> onOpenTask;

  const DriverCompletedTasksScreen({super.key, required this.onOpenTask});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DriverController>();
    final tasks = controller.completedTasks;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: Column(
        children: [
          ReceivingTopHeader(
            height: MediaQuery.of(context).size.height * 0.22,
            title: 'Completed Tasks',
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -35),
              child: Builder(
                builder: (context) {
                  if (controller.isLoadingTasks && tasks.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.tasksError != null && tasks.isEmpty) {
                    return _TaskListError(
                      message: controller.tasksError!,
                      onRetry: controller.fetchTasks,
                    );
                  }

                  if (tasks.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: controller.fetchTasks,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 160),
                          Center(
                            child: Text(
                              'No completed tasks',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.fetchTasks,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return DriverTaskCard(
                          task: task,
                          onTap: () => onOpenTask(task),
                        );
                      },
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

class _TaskListError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TaskListError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
