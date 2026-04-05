// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TrackPoint {
  double get lat => throw _privateConstructorUsedError;
  double get lon => throw _privateConstructorUsedError;
  double get elevationM => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  double get speedKmh => throw _privateConstructorUsedError;
  int? get heartRate => throw _privateConstructorUsedError;
  SegmentType? get segmentType => throw _privateConstructorUsedError;

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrackPointCopyWith<TrackPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrackPointCopyWith<$Res> {
  factory $TrackPointCopyWith(
          TrackPoint value, $Res Function(TrackPoint) then) =
      _$TrackPointCopyWithImpl<$Res, TrackPoint>;
  @useResult
  $Res call(
      {double lat,
      double lon,
      double elevationM,
      DateTime timestamp,
      double speedKmh,
      int? heartRate,
      SegmentType? segmentType});
}

/// @nodoc
class _$TrackPointCopyWithImpl<$Res, $Val extends TrackPoint>
    implements $TrackPointCopyWith<$Res> {
  _$TrackPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lon = null,
    Object? elevationM = null,
    Object? timestamp = null,
    Object? speedKmh = null,
    Object? heartRate = freezed,
    Object? segmentType = freezed,
  }) {
    return _then(_value.copyWith(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lon: null == lon
          ? _value.lon
          : lon // ignore: cast_nullable_to_non_nullable
              as double,
      elevationM: null == elevationM
          ? _value.elevationM
          : elevationM // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      speedKmh: null == speedKmh
          ? _value.speedKmh
          : speedKmh // ignore: cast_nullable_to_non_nullable
              as double,
      heartRate: freezed == heartRate
          ? _value.heartRate
          : heartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      segmentType: freezed == segmentType
          ? _value.segmentType
          : segmentType // ignore: cast_nullable_to_non_nullable
              as SegmentType?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrackPointImplCopyWith<$Res>
    implements $TrackPointCopyWith<$Res> {
  factory _$$TrackPointImplCopyWith(
          _$TrackPointImpl value, $Res Function(_$TrackPointImpl) then) =
      __$$TrackPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double lat,
      double lon,
      double elevationM,
      DateTime timestamp,
      double speedKmh,
      int? heartRate,
      SegmentType? segmentType});
}

/// @nodoc
class __$$TrackPointImplCopyWithImpl<$Res>
    extends _$TrackPointCopyWithImpl<$Res, _$TrackPointImpl>
    implements _$$TrackPointImplCopyWith<$Res> {
  __$$TrackPointImplCopyWithImpl(
      _$TrackPointImpl _value, $Res Function(_$TrackPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lon = null,
    Object? elevationM = null,
    Object? timestamp = null,
    Object? speedKmh = null,
    Object? heartRate = freezed,
    Object? segmentType = freezed,
  }) {
    return _then(_$TrackPointImpl(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lon: null == lon
          ? _value.lon
          : lon // ignore: cast_nullable_to_non_nullable
              as double,
      elevationM: null == elevationM
          ? _value.elevationM
          : elevationM // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      speedKmh: null == speedKmh
          ? _value.speedKmh
          : speedKmh // ignore: cast_nullable_to_non_nullable
              as double,
      heartRate: freezed == heartRate
          ? _value.heartRate
          : heartRate // ignore: cast_nullable_to_non_nullable
              as int?,
      segmentType: freezed == segmentType
          ? _value.segmentType
          : segmentType // ignore: cast_nullable_to_non_nullable
              as SegmentType?,
    ));
  }
}

/// @nodoc

class _$TrackPointImpl extends _TrackPoint with DiagnosticableTreeMixin {
  const _$TrackPointImpl(
      {required this.lat,
      required this.lon,
      required this.elevationM,
      required this.timestamp,
      required this.speedKmh,
      this.heartRate,
      this.segmentType})
      : super._();

  @override
  final double lat;
  @override
  final double lon;
  @override
  final double elevationM;
  @override
  final DateTime timestamp;
  @override
  final double speedKmh;
  @override
  final int? heartRate;
  @override
  final SegmentType? segmentType;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TrackPoint(lat: $lat, lon: $lon, elevationM: $elevationM, timestamp: $timestamp, speedKmh: $speedKmh, heartRate: $heartRate, segmentType: $segmentType)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'TrackPoint'))
      ..add(DiagnosticsProperty('lat', lat))
      ..add(DiagnosticsProperty('lon', lon))
      ..add(DiagnosticsProperty('elevationM', elevationM))
      ..add(DiagnosticsProperty('timestamp', timestamp))
      ..add(DiagnosticsProperty('speedKmh', speedKmh))
      ..add(DiagnosticsProperty('heartRate', heartRate))
      ..add(DiagnosticsProperty('segmentType', segmentType));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrackPointImpl &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lon, lon) || other.lon == lon) &&
            (identical(other.elevationM, elevationM) ||
                other.elevationM == elevationM) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.speedKmh, speedKmh) ||
                other.speedKmh == speedKmh) &&
            (identical(other.heartRate, heartRate) ||
                other.heartRate == heartRate) &&
            (identical(other.segmentType, segmentType) ||
                other.segmentType == segmentType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, lat, lon, elevationM, timestamp,
      speedKmh, heartRate, segmentType);

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrackPointImplCopyWith<_$TrackPointImpl> get copyWith =>
      __$$TrackPointImplCopyWithImpl<_$TrackPointImpl>(this, _$identity);
}

abstract class _TrackPoint extends TrackPoint {
  const factory _TrackPoint(
      {required final double lat,
      required final double lon,
      required final double elevationM,
      required final DateTime timestamp,
      required final double speedKmh,
      final int? heartRate,
      final SegmentType? segmentType}) = _$TrackPointImpl;
  const _TrackPoint._() : super._();

  @override
  double get lat;
  @override
  double get lon;
  @override
  double get elevationM;
  @override
  DateTime get timestamp;
  @override
  double get speedKmh;
  @override
  int? get heartRate;
  @override
  SegmentType? get segmentType;

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrackPointImplCopyWith<_$TrackPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
