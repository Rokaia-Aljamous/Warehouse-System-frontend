import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/models/driver_profile_model.dart';
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
}
