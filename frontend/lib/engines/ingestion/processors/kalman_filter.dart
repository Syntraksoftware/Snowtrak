import '../parsers/gpx_parser.dart';

const double _processNoiseQ = 1e-5;
const double _measurementNoiseBaseR = 1e-3;
const double _alpineMeasurementMultiplier = 3.0;

/// Applies a 2D constant-velocity Kalman filter on lat/lon.
///
/// State vector: [lat, lon, vLat, vLon]
/// Q (process noise): 1e-5
/// R (measurement noise): 1e-3 base, tuned higher for alpine skiing.
List<RawPoint> apply(List<RawPoint> points) {
  if (points.length <= 1) {
    return List<RawPoint>.from(points);
  }

  final filtered = <RawPoint>[];
  const measurementNoise = _measurementNoiseBaseR * _alpineMeasurementMultiplier;

  var x = <double>[points.first.lat, points.first.lon, 0.0, 0.0];
  var p = _identity4();

  filtered.add(points.first);

  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final curr = points[i];
    final dt = _deltaTimeSeconds(prev.time, curr.time);

    final f = _stateTransition(dt);
    final q = _processNoise(dt, _processNoiseQ);

    x = _mat4Vec4(f, x);
    p = _mat4Add(_mat4Mul(_mat4Mul(f, p), _mat4Transpose(f)), q);

    final z = <double>[curr.lat, curr.lon];
    final h = _measurementMatrix();
    final r = _measurementNoise(measurementNoise);

    final y = _vec2Sub(z, _mat2x4Vec4(h, x));
    final s = _mat2Add(_mat2Mul(_mat2x4Mul(h, _mat4Mul2x4T(p, h)), _identity2()), r);
    final sInv = _mat2Inverse(s);

    final k = _mat4x2Mul(_mat4Mul4x2(p, _mat2x4Transpose(h)), sInv);

    x = _vec4Add(x, _mat4x2Vec2(k, y));

    final kh = _mat4x4Mul4x2x2x4(k, h);
    p = _mat4Mul(_mat4Sub(_identity4(), kh), p);

    filtered.add(
      RawPoint(
        lat: x[0],
        lon: x[1],
        ele: curr.ele,
        time: curr.time,
      ),
    );
  }

  return filtered;
}

double _deltaTimeSeconds(DateTime? prev, DateTime? curr) {
  if (prev == null || curr == null) {
    return 1.0;
  }
  final ms = curr.difference(prev).inMilliseconds;
  if (ms <= 0) {
    return 1.0;
  }
  return ms / 1000.0;
}

List<List<double>> _identity4() => <List<double>>[
      <double>[1, 0, 0, 0],
      <double>[0, 1, 0, 0],
      <double>[0, 0, 1, 0],
      <double>[0, 0, 0, 1],
    ];

List<List<double>> _identity2() => <List<double>>[
      <double>[1, 0],
      <double>[0, 1],
    ];

List<List<double>> _stateTransition(double dt) => <List<double>>[
      <double>[1, 0, dt, 0],
      <double>[0, 1, 0, dt],
      <double>[0, 0, 1, 0],
      <double>[0, 0, 0, 1],
    ];

List<List<double>> _measurementMatrix() => <List<double>>[
      <double>[1, 0, 0, 0],
      <double>[0, 1, 0, 0],
    ];

List<List<double>> _measurementNoise(double r) => <List<double>>[
      <double>[r, 0],
      <double>[0, r],
    ];

List<List<double>> _processNoise(double dt, double q) {
  final dt2 = dt * dt;
  final dt3 = dt2 * dt;
  final dt4 = dt2 * dt2;

  return <List<double>>[
    <double>[q * dt4 / 4.0, 0, q * dt3 / 2.0, 0],
    <double>[0, q * dt4 / 4.0, 0, q * dt3 / 2.0],
    <double>[q * dt3 / 2.0, 0, q * dt2, 0],
    <double>[0, q * dt3 / 2.0, 0, q * dt2],
  ];
}

List<double> _mat4Vec4(List<List<double>> m, List<double> v) =>
    List<double>.generate(4, (r) => _dot(m[r], v));

List<double> _mat2x4Vec4(List<List<double>> m, List<double> v) =>
    List<double>.generate(2, (r) => _dot(m[r], v));

List<double> _mat4x2Vec2(List<List<double>> m, List<double> v) =>
    List<double>.generate(4, (r) => m[r][0] * v[0] + m[r][1] * v[1]);

List<List<double>> _mat4Mul(List<List<double>> a, List<List<double>> b) {
  final out = List<List<double>>.generate(4, (_) => List<double>.filled(4, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      for (var k = 0; k < 4; k++) {
        out[r][c] += a[r][k] * b[k][c];
      }
    }
  }
  return out;
}

List<List<double>> _mat2Mul(List<List<double>> a, List<List<double>> b) {
  final out = List<List<double>>.generate(2, (_) => List<double>.filled(2, 0));
  for (var r = 0; r < 2; r++) {
    for (var c = 0; c < 2; c++) {
      for (var k = 0; k < 2; k++) {
        out[r][c] += a[r][k] * b[k][c];
      }
    }
  }
  return out;
}

List<List<double>> _mat2x4Mul(List<List<double>> a, List<List<double>> b) {
  final out = List<List<double>>.generate(2, (_) => List<double>.filled(2, 0));
  for (var r = 0; r < 2; r++) {
    for (var c = 0; c < 2; c++) {
      for (var k = 0; k < 4; k++) {
        out[r][c] += a[r][k] * b[k][c];
      }
    }
  }
  return out;
}

List<List<double>> _mat4Mul2x4T(List<List<double>> p, List<List<double>> h) {
  final ht = _mat2x4Transpose(h);
  final out = List<List<double>>.generate(4, (_) => List<double>.filled(2, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 2; c++) {
      for (var k = 0; k < 4; k++) {
        out[r][c] += p[r][k] * ht[k][c];
      }
    }
  }
  return out;
}

List<List<double>> _mat4Mul4x2(List<List<double>> p, List<List<double>> ht) {
  final out = List<List<double>>.generate(4, (_) => List<double>.filled(2, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 2; c++) {
      for (var k = 0; k < 4; k++) {
        out[r][c] += p[r][k] * ht[k][c];
      }
    }
  }
  return out;
}

List<List<double>> _mat4x2Mul(List<List<double>> a, List<List<double>> b) {
  final out = List<List<double>>.generate(4, (_) => List<double>.filled(2, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 2; c++) {
      out[r][c] = a[r][0] * b[0][c] + a[r][1] * b[1][c];
    }
  }
  return out;
}

List<List<double>> _mat4x4Mul4x2x2x4(List<List<double>> k, List<List<double>> h) {
  final out = List<List<double>>.generate(4, (_) => List<double>.filled(4, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      for (var i = 0; i < 2; i++) {
        out[r][c] += k[r][i] * h[i][c];
      }
    }
  }
  return out;
}

List<List<double>> _mat4Transpose(List<List<double>> m) {
  final out = List<List<double>>.generate(4, (_) => List<double>.filled(4, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      out[c][r] = m[r][c];
    }
  }
  return out;
}

List<List<double>> _mat2x4Transpose(List<List<double>> m) => <List<double>>[
      <double>[m[0][0], m[1][0]],
      <double>[m[0][1], m[1][1]],
      <double>[m[0][2], m[1][2]],
      <double>[m[0][3], m[1][3]],
    ];

List<List<double>> _mat4Add(List<List<double>> a, List<List<double>> b) {
  final out = List<List<double>>.generate(4, (_) => List<double>.filled(4, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      out[r][c] = a[r][c] + b[r][c];
    }
  }
  return out;
}

List<List<double>> _mat2Add(List<List<double>> a, List<List<double>> b) {
  final out = List<List<double>>.generate(2, (_) => List<double>.filled(2, 0));
  for (var r = 0; r < 2; r++) {
    for (var c = 0; c < 2; c++) {
      out[r][c] = a[r][c] + b[r][c];
    }
  }
  return out;
}

List<List<double>> _mat4Sub(List<List<double>> a, List<List<double>> b) {
  final out = List<List<double>>.generate(4, (_) => List<double>.filled(4, 0));
  for (var r = 0; r < 4; r++) {
    for (var c = 0; c < 4; c++) {
      out[r][c] = a[r][c] - b[r][c];
    }
  }
  return out;
}

List<List<double>> _mat2Inverse(List<List<double>> m) {
  final det = m[0][0] * m[1][1] - m[0][1] * m[1][0];
  if (det.abs() < 1e-12) {
    return _identity2();
  }
  final invDet = 1.0 / det;
  return <List<double>>[
    <double>[m[1][1] * invDet, -m[0][1] * invDet],
    <double>[-m[1][0] * invDet, m[0][0] * invDet],
  ];
}

List<double> _vec2Sub(List<double> a, List<double> b) =>
    <double>[a[0] - b[0], a[1] - b[1]];

List<double> _vec4Add(List<double> a, List<double> b) =>
    <double>[a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3]];

double _dot(List<double> a, List<double> b) {
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    sum += a[i] * b[i];
  }
  return sum;
}
