import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/models/driver_profile_model.dart';
import 'package:stock_app/models/driver_notification_model.dart';
import 'package:stock_app/models/driver_task_model.dart';

void main() {
  test('driver tasks response combines the three backend task groups', () {
    final response = DriverTasksResponse.fromJson({
      'order_delivery': {
        'in_preparation': [
          {
            'id': 11,
            'task_type': 'order_delivery',
            'status': 'in_preparation',
            'related_id': 7,
            'related': {
              'customer': {
                'id': 2,
                'full_name': 'Customer One',
                'phone_number': '0999000000',
              },
              'customer_location': 'Damascus',
              'customer_latitude': 33.5138,
              'customer_longitude': 36.2765,
            },
          },
        ],
        'completed': [],
      },
      'transfer_delivery': {'in_preparation': [], 'completed': []},
      'return_pickup': {'in_preparation': [], 'completed': []},
    });

    expect(response.pending, hasLength(1));
    expect(response.pending.first.customerName, 'Customer One');
    expect(response.pending.first.hasCoordinates, isTrue);
    expect(response.pending.first.referenceLabel, 'Order #7');
  });

  test('driver profile rewrites loopback image URL to the API host', () {
    final profile = DriverProfile.fromJson({
      'full_name': 'Driver One',
      'user_name': 'driver_one',
      'phone_number': '0999000000',
      'profile_image':
          'http://127.0.0.1:8000/storage/images/profiles/avatar.jpg',
      'role': 'driver',
    }, apiBaseUrl: 'http://10.65.1.21:8000');

    expect(
      profile.imageUrl,
      'http://10.65.1.21:8000/storage/images/profiles/avatar.jpg',
    );
  });

  test('daily summary uses backend totals and percentage', () {
    final summary = DriverDailySummary.fromJson({
      'date': '2026-08-17',
      'total': 5,
      'in_preparation': 3,
      'completed': 2,
      'completion_percentage': 40,
    });

    expect(summary.total, 5);
    expect(summary.completed, 2);
    expect(summary.completionPercentage, 40);
  });

  test('return pickup exposes its original order id without guessing', () {
    final task = DriverTask.fromJson({
      'id': 22,
      'task_type': 'return_pickup',
      'status': 'in_preparation',
      'related_id': 19,
      'related': {
        'order_id': 7,
        'return_type': 'customer_return',
        'return_reason': 'Damaged package',
      },
    });

    expect(task.relatedId, 19);
    expect(task.orderId, 7);
    expect(task.returnReason, 'Damaged package');
  });

  test('order details enrich return task with customer destination', () {
    final task = DriverTask.fromJson({
      'id': 22,
      'task_type': 'return_pickup',
      'status': 'in_preparation',
      'related_id': 19,
      'related': {'order_id': 7},
    });

    final enriched = task.withOrderDetails({
      'id': 7,
      'customer': {
        'id': 2,
        'full_name': 'Customer One',
        'phone_number': '0999000000',
      },
      'customer_location': 'Damascus',
      'customer_latitude': '33.5138',
      'customer_longitude': '36.2765',
      'order_qr_code': 'ORDER-7',
    });

    expect(enriched.customerName, 'Customer One');
    expect(enriched.hasCoordinates, isTrue);
    expect(enriched.orderQrCode, 'ORDER-7');
  });

  test('return details use return id and parse nested returned products', () {
    final task = DriverTask.fromJson({
      'id': 22,
      'task_type': 'return_pickup',
      'status': 'in_preparation',
      'related_id': 19,
      'related': {'order_id': 7},
    });

    final enriched = task.withReturnDetails({
      'id': 19,
      'order_id': 7,
      'status': 'approved',
      'return_type': 'customer_return',
      'return_reason': 'Wrong item',
      'order': {'id': 7, 'order_qr_code': 'ORDER-7'},
      'items': [
        {
          'quantity': 2,
          'order_item': {
            'product_id': 5,
            'product': {'id': 5, 'name': 'Product Five'},
          },
        },
      ],
    });

    expect(enriched.relatedId, 19);
    expect(enriched.orderId, 7);
    expect(enriched.returnReason, 'Wrong item');
    expect(enriched.items, hasLength(1));
    expect(enriched.items.first.name, 'Product Five');
    expect(enriched.items.first.quantity, 2);
  });

  test('driver notification parses unread backend payload and can be read', () {
    final notification = DriverNotification.fromJson({
      'id': 91,
      'title': 'Deliver Order Task',
      'message': 'You have been assigned order #17.',
      'notification_type': 'task_deliver_order',
      'data': {'task_id': 44},
      'reference_id': 44,
      'read_at': null,
      'created_at': '2026-08-18T12:00:00Z',
    });

    expect(notification.id, 91);
    expect(notification.isRead, isFalse);
    expect(notification.data['task_id'], 44);
    expect(notification.markRead().isRead, isTrue);
  });
}
