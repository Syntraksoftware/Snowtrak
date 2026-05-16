import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/map/color_mode_styler.dart';

void main() {
  test('routeColorExpression changes by color mode', () {
    const styler = MapColorModeStyler();

    final segmentExpression = styler.routeColorExpression(MapColorMode.segment) as List<dynamic>;
    final speedExpression = styler.routeColorExpression(MapColorMode.speed) as List<dynamic>;
    final elevationExpression = styler.routeColorExpression(MapColorMode.elevation) as List<dynamic>;

    expect(segmentExpression.first, 'match');
    expect(segmentExpression[1], ['get', 'segmentType']);
    expect(speedExpression.first, 'interpolate');
    expect(speedExpression[2], ['get', 'speedKmh']);
    expect(elevationExpression.first, 'interpolate');
    expect(elevationExpression[2], ['get', 'elevationM']);
  });
}