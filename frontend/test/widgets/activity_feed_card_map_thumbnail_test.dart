import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/models/location.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_card_map_thumbnail.dart';

void main() {
  testWidgets('shows Image.network when imageUrl is provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityFeedCardMapThumbnail(
          locations: [
            Location(
              id: 'loc1',
              activityId: 'activity_1',
              latitude: 10.0,
              longitude: 10.0,
              timestamp: DateTime.parse('2025-01-01T00:00:00Z'),
            ),
            Location(
              id: 'loc2',
              activityId: 'activity_1',
              latitude: 11.0,
              longitude: 11.0,
              timestamp: DateTime.parse('2025-01-01T00:01:00Z'),
            ),
          ],
          routeColor: Colors.red,
          imageUrl: 'https://example.com/thumbnail.png',
        ),
      ),
    );

    // Allow network image widget to build
    await tester.pumpAndSettle();

    // Expect an Image widget to be present
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('falls back to CustomPaint when imageUrl is missing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityFeedCardMapThumbnail(
          locations: [
            Location(
              id: 'loc1',
              activityId: 'activity_1',
              latitude: 10.0,
              longitude: 10.0,
              timestamp: DateTime.parse('2025-01-01T00:00:00Z'),
            ),
            Location(
              id: 'loc2',
              activityId: 'activity_1',
              latitude: 11.0,
              longitude: 11.0,
              timestamp: DateTime.parse('2025-01-01T00:01:00Z'),
            ),
          ],
          routeColor: Colors.blue,
          imageUrl: null,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Expect at least one CustomPaint to be used for vector preview
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
