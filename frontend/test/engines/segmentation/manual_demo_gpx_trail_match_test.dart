import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/gps_ingestion_engine.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/elevation_corrector.dart';
import 'package:syntrak/engines/segmentation/segment_detection_engine.dart';
import 'package:syntrak/engines/segmentation/trail_matcher.dart';
import 'package:syntrak/models/segment.dart';

const double _profileToleranceM = 120.0;

void main() {
  test(
    'manual demo GPX trail matcher check against filename',
    () async {
    final gpxPaths = _resolveDemoGpxPaths();

    for (final path in gpxPaths) {
      expect(File(path).existsSync(), isTrue, reason: 'Missing demo GPX: $path');
    }

    final ingestion = GpsIngestionEngine(
      elevationCorrector: ElevationCorrector(apiClient: _MockDemApiClient()),
      idFactory: () => 'demo-track',
    );

    final matcher = TrailMatcher(apiClient: _FallbackTrailMatchApiClient());
    final segmentation = SegmentDetectionEngine(trailMatcher: matcher);
    const enforceExpectedProfile =
        String.fromEnvironment('ENFORCE_DEMO_EXPECTED', defaultValue: 'false') == 'true';

    final results = <_DemoResult>[];
    final expectedProfiles = <String, _ExpectedProfile>{
      'hoferspitze': const _ExpectedProfile(ascentM: 550.0, descentM: 550.0),
      'juppenspitze': const _ExpectedProfile(ascentM: 76.0, descentM: 734.0),
      'auenfelderhorn': const _ExpectedProfile(ascentM: 110.0, descentM: 550.0),
    };

    for (final path in gpxPaths) {
      final file = File(path);
      final raw = parseGpxFile(file);
      final profile = _computeProfile(raw);

      final track = await ingestion.processGpxFile(file);
      final segments = await segmentation.detect(track);

      final descents = segments.where((s) => s.type == SegmentType.descent).toList();
      final matchedNames = descents
          .map((s) => s.trailName)
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toSet()
          .toList();

      final fileStem = file.uri.pathSegments.last.split('.').first;
      final fileNorm = _normalize(fileStem);
      final expected = expectedProfiles[fileNorm];
      final nearestExpectedName = _nearestExpectedProfileName(profile, expectedProfiles);
      final profileMatchesExpected = expected == null
          ? true
          : (profile.ascentM - expected.ascentM).abs() <= _profileToleranceM &&
                (profile.descentM - expected.descentM).abs() <= _profileToleranceM;

      final hasNameMatch = matchedNames.any((name) {
        final n = _normalize(name);
        return n.contains(fileNorm) || fileNorm.contains(n);
      });

      results.add(
        _DemoResult(
          fileName: fileStem,
          descentCount: descents.length,
          matchedTrailNames: matchedNames,
          hasFilenameMatch: hasNameMatch,
          ascentM: profile.ascentM,
          descentM: profile.descentM,
          expectedAscentM: expected?.ascentM,
          expectedDescentM: expected?.descentM,
          profileMatchesExpected: profileMatchesExpected,
          nearestExpectedName: nearestExpectedName,
        ),
      );
    }

    // Print a concise report to terminal for manual verification.
    for (final r in results) {
      // ignore: avoid_print
      print(
        '[demo-check] file=${r.fileName} descents=${r.descentCount} '
        'matched=${r.matchedTrailNames} filenameMatch=${r.hasFilenameMatch} '
        'ascent=${r.ascentM.toStringAsFixed(1)} descent=${r.descentM.toStringAsFixed(1)} '
        'expected=${r.expectedAscentM?.toStringAsFixed(0) ?? '-'}'
        '/${r.expectedDescentM?.toStringAsFixed(0) ?? '-'} '
        'profileOk=${r.profileMatchesExpected} nearestExpected=${r.nearestExpectedName}',
      );
    }

    if (enforceExpectedProfile) {
      final skiOnly = results.where((r) => r.expectedAscentM != null);
      for (final r in skiOnly) {
        expect(
          r.profileMatchesExpected,
          isTrue,
          reason:
              'Profile mismatch for ${r.fileName}: actual ${r.ascentM.toStringAsFixed(1)}/${r.descentM.toStringAsFixed(1)} '
              'expected ${r.expectedAscentM!.toStringAsFixed(1)}/${r.expectedDescentM!.toStringAsFixed(1)}',
        );
      }
    }

    // Ensure the check itself executed and returned per-file outputs.
    expect(results, hasLength(gpxPaths.length));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

List<String> _resolveDemoGpxPaths() {
  const explicit = String.fromEnvironment('DEMO_GPX_FILES', defaultValue: '');
  if (explicit.trim().isNotEmpty) {
    return explicit
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  return <String>[
    '../Auenfelder-horn.gpx',
    '../Ho\u0308ferspitze.gpx',
    '../juppenspitze.gpx',
    '../demo_notski.gpx',
  ];
}

String _normalize(String input) {
  var out = input.toLowerCase();
  out = out.replaceAll('\u0308', '');
  out = out
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');
  out = out.replaceAll('-', '').replaceAll('_', '').replaceAll(' ', '');
  out = out.replaceAll(RegExp('[^a-z0-9]'), '');
  return out;
}

class _DemoResult {
  const _DemoResult({
    required this.fileName,
    required this.descentCount,
    required this.matchedTrailNames,
    required this.hasFilenameMatch,
    required this.ascentM,
    required this.descentM,
    required this.expectedAscentM,
    required this.expectedDescentM,
    required this.profileMatchesExpected,
    required this.nearestExpectedName,
  });

  final String fileName;
  final int descentCount;
  final List<String> matchedTrailNames;
  final bool hasFilenameMatch;
  final double ascentM;
  final double descentM;
  final double? expectedAscentM;
  final double? expectedDescentM;
  final bool profileMatchesExpected;
  final String nearestExpectedName;
}

class _ExpectedProfile {
  const _ExpectedProfile({required this.ascentM, required this.descentM});

  final double ascentM;
  final double descentM;
}

class _TrackProfile {
  const _TrackProfile({required this.ascentM, required this.descentM});

  final double ascentM;
  final double descentM;
}

_TrackProfile _computeProfile(List<RawPoint> points) {
  if (points.length < 2) {
    return const _TrackProfile(ascentM: 0, descentM: 0);
  }

  var ascent = 0.0;
  var descent = 0.0;

  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1].ele;
    final curr = points[i].ele;
    if (prev == null || curr == null) {
      continue;
    }
    final delta = curr - prev;
    if (delta > 0) {
      ascent += delta;
    } else if (delta < 0) {
      descent += -delta;
    }
  }

  return _TrackProfile(ascentM: ascent, descentM: descent);
}

String _nearestExpectedProfileName(
  _TrackProfile profile,
  Map<String, _ExpectedProfile> expected,
) {
  var bestName = 'n/a';
  var bestScore = double.infinity;

  expected.forEach((name, target) {
    final score =
        (profile.ascentM - target.ascentM).abs() + (profile.descentM - target.descentM).abs();
    if (score < bestScore) {
      bestScore = score;
      bestName = name;
    }
  });

  return bestName;
}

class _MockDemApiClient implements ApiClient {
  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final points = (data?['points'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return <String, dynamic>{
      'points': points
          .map(
            (p) => <String, dynamic>{
              'lat': p['lat'],
              'lon': p['lon'],
              'elevation_m':
                  p['elevation_m'] ??
                  (1000.0 + (p['lat'] as num).toDouble() * 0.5 + (p['lon'] as num).toDouble() * 0.2),
              'timestamp': p['timestamp'],
              'speed_kmh': p['speed_kmh'] ?? 0.0,
              'segment_type': p['segment_type'],
            },
          )
          .toList(),
    };
  }
}

class _FallbackTrailMatchApiClient implements TrailMatchApiClient {
  _FallbackTrailMatchApiClient()
      : _clients = <Dio>[
          ..._candidateClients(),
        ];

  final List<Dio> _clients;

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    DioException? lastError;

    for (final client in _clients) {
      try {
        final response = await client.post(path, data: data);
        return Map<String, dynamic>.from(response.data as Map);
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        if (code == 404) {
          continue;
        }
      }
    }

    throw StateError(
      'No reachable trail matcher endpoint for $path. Last error: '
      '${lastError?.message ?? 'unknown'}',
    );
  }
}

List<Dio> _candidateClients() {
  const envBase = String.fromEnvironment('TRAIL_MATCH_BASE_URL', defaultValue: 'http://localhost:5200');
  final base = envBase.endsWith('/') ? envBase.substring(0, envBase.length - 1) : envBase;

  final candidates = <String>{
    '$base/api',
    base,
  };

  return candidates.map((u) => Dio(BaseOptions(baseUrl: u))).toList();
}
