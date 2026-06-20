import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/features/track_pipeline/data/mappers/pipeline_json_mapper.dart';
import 'package:syntrak/models/processed_track.dart';

void main() {
  const mapper = PipelineJsonMapper();

  test('buildNivusRequest uses snake_case aligned with backend contract', () {
    final body = mapper.buildNivusRequest(
      rawPoints: const [
        RawPoint(lat: 46.8, lon: 9.8, ele: 2100, time: null),
      ],
      recordedAt: DateTime.utc(2024, 1, 15, 10, 30),
      sourceType: SourceType.live,
      trackId: 'track-1',
      matchTrails: false,
    );

    expect(body['id'], 'track-1');
    expect(body['source_type'], 'live');
    expect(body['match_trails'], isFalse);
    expect(body['points'], isA<List>());
    expect(body['points'][0]['lat'], 46.8);
    expect(body['points'][0]['speed_kmh'], 0.0);
  });

  test('parseNivusResponse maps stats and segments', () {
    final result = mapper.parseNivusResponse({
      'processed_track': {
        'id': 't1',
        'recorded_at': '2024-01-15T10:30:00Z',
        'source_type': 'live',
        'points': [
          {
            'lat': 46.8,
            'lon': 9.8,
            'elevation_m': 2100.0,
            'timestamp': '2024-01-15T10:30:00Z',
            'speed_kmh': 12.5,
          },
        ],
      },
      'segments': [
        {
          'type': 'descent',
          'start_index': 0,
          'end_index': 0,
          'trail_name': 'Blue Run',
          'difficulty': 'blue',
          'points': [
            {
              'lat': 46.8,
              'lon': 9.8,
              'elevation_m': 2100.0,
              'timestamp': '2024-01-15T10:30:00Z',
              'speed_kmh': 12.5,
            },
          ],
        },
      ],
      'stats': {
        'total_distance_km': 3.2,
        'total_vertical_drop_m': 450.0,
        'top_speed_kmh': 62.0,
        'avg_speed_kmh': 28.0,
        'moving_time_s': 1200.0,
        'trail_count': 1,
      },
      'run_summaries': [],
    });

    expect(result.processedTrack.points, hasLength(1));
    expect(result.segments.first.trailName, 'Blue Run');
    expect(result.stats?.totalDistanceKm, 3.2);
    expect(result.stats?.trailCount, 1);
  });
}
