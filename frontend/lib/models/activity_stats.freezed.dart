// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ActivityStats {
  double get totalDistanceKm => throw _privateConstructorUsedError;
  double get totalVerticalDropM => throw _privateConstructorUsedError;
  double get topSpeedKmh => throw _privateConstructorUsedError;
  double get avgSpeedKmh => throw _privateConstructorUsedError;
  Duration get movingTime => throw _privateConstructorUsedError;

  /// Distinct named trails touched during the activity (Engine 3).
  int get trailCount => throw _privateConstructorUsedError;

  /// Create a copy of ActivityStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActivityStatsCopyWith<ActivityStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActivityStatsCopyWith<$Res> {
  factory $ActivityStatsCopyWith(
          ActivityStats value, $Res Function(ActivityStats) then) =
      _$ActivityStatsCopyWithImpl<$Res, ActivityStats>;
  @useResult
  $Res call(
      {double totalDistanceKm,
      double totalVerticalDropM,
      double topSpeedKmh,
      double avgSpeedKmh,
      Duration movingTime,
      int trailCount});
}

/// @nodoc
class _$ActivityStatsCopyWithImpl<$Res, $Val extends ActivityStats>
    implements $ActivityStatsCopyWith<$Res> {
  _$ActivityStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActivityStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalDistanceKm = null,
    Object? totalVerticalDropM = null,
    Object? topSpeedKmh = null,
    Object? avgSpeedKmh = null,
    Object? movingTime = null,
    Object? trailCount = null,
  }) {
    return _then(_value.copyWith(
      totalDistanceKm: null == totalDistanceKm
          ? _value.totalDistanceKm
          : totalDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      totalVerticalDropM: null == totalVerticalDropM
          ? _value.totalVerticalDropM
          : totalVerticalDropM // ignore: cast_nullable_to_non_nullable
              as double,
      topSpeedKmh: null == topSpeedKmh
          ? _value.topSpeedKmh
          : topSpeedKmh // ignore: cast_nullable_to_non_nullable
              as double,
      avgSpeedKmh: null == avgSpeedKmh
          ? _value.avgSpeedKmh
          : avgSpeedKmh // ignore: cast_nullable_to_non_nullable
              as double,
      movingTime: null == movingTime
          ? _value.movingTime
          : movingTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      trailCount: null == trailCount
          ? _value.trailCount
          : trailCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActivityStatsImplCopyWith<$Res>
    implements $ActivityStatsCopyWith<$Res> {
  factory _$$ActivityStatsImplCopyWith(
          _$ActivityStatsImpl value, $Res Function(_$ActivityStatsImpl) then) =
      __$$ActivityStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double totalDistanceKm,
      double totalVerticalDropM,
      double topSpeedKmh,
      double avgSpeedKmh,
      Duration movingTime,
      int trailCount});
}

/// @nodoc
class __$$ActivityStatsImplCopyWithImpl<$Res>
    extends _$ActivityStatsCopyWithImpl<$Res, _$ActivityStatsImpl>
    implements _$$ActivityStatsImplCopyWith<$Res> {
  __$$ActivityStatsImplCopyWithImpl(
      _$ActivityStatsImpl _value, $Res Function(_$ActivityStatsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActivityStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalDistanceKm = null,
    Object? totalVerticalDropM = null,
    Object? topSpeedKmh = null,
    Object? avgSpeedKmh = null,
    Object? movingTime = null,
    Object? trailCount = null,
  }) {
    return _then(_$ActivityStatsImpl(
      totalDistanceKm: null == totalDistanceKm
          ? _value.totalDistanceKm
          : totalDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      totalVerticalDropM: null == totalVerticalDropM
          ? _value.totalVerticalDropM
          : totalVerticalDropM // ignore: cast_nullable_to_non_nullable
              as double,
      topSpeedKmh: null == topSpeedKmh
          ? _value.topSpeedKmh
          : topSpeedKmh // ignore: cast_nullable_to_non_nullable
              as double,
      avgSpeedKmh: null == avgSpeedKmh
          ? _value.avgSpeedKmh
          : avgSpeedKmh // ignore: cast_nullable_to_non_nullable
              as double,
      movingTime: null == movingTime
          ? _value.movingTime
          : movingTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      trailCount: null == trailCount
          ? _value.trailCount
          : trailCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$ActivityStatsImpl extends _ActivityStats with DiagnosticableTreeMixin {
  const _$ActivityStatsImpl(
      {required this.totalDistanceKm,
      required this.totalVerticalDropM,
      required this.topSpeedKmh,
      required this.avgSpeedKmh,
      required this.movingTime,
      required this.trailCount})
      : super._();

  @override
  final double totalDistanceKm;
  @override
  final double totalVerticalDropM;
  @override
  final double topSpeedKmh;
  @override
  final double avgSpeedKmh;
  @override
  final Duration movingTime;

  /// Distinct named trails touched during the activity (Engine 3).
  @override
  final int trailCount;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ActivityStats(totalDistanceKm: $totalDistanceKm, totalVerticalDropM: $totalVerticalDropM, topSpeedKmh: $topSpeedKmh, avgSpeedKmh: $avgSpeedKmh, movingTime: $movingTime, trailCount: $trailCount)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ActivityStats'))
      ..add(DiagnosticsProperty('totalDistanceKm', totalDistanceKm))
      ..add(DiagnosticsProperty('totalVerticalDropM', totalVerticalDropM))
      ..add(DiagnosticsProperty('topSpeedKmh', topSpeedKmh))
      ..add(DiagnosticsProperty('avgSpeedKmh', avgSpeedKmh))
      ..add(DiagnosticsProperty('movingTime', movingTime))
      ..add(DiagnosticsProperty('trailCount', trailCount));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActivityStatsImpl &&
            (identical(other.totalDistanceKm, totalDistanceKm) ||
                other.totalDistanceKm == totalDistanceKm) &&
            (identical(other.totalVerticalDropM, totalVerticalDropM) ||
                other.totalVerticalDropM == totalVerticalDropM) &&
            (identical(other.topSpeedKmh, topSpeedKmh) ||
                other.topSpeedKmh == topSpeedKmh) &&
            (identical(other.avgSpeedKmh, avgSpeedKmh) ||
                other.avgSpeedKmh == avgSpeedKmh) &&
            (identical(other.movingTime, movingTime) ||
                other.movingTime == movingTime) &&
            (identical(other.trailCount, trailCount) ||
                other.trailCount == trailCount));
  }

  @override
  int get hashCode => Object.hash(runtimeType, totalDistanceKm,
      totalVerticalDropM, topSpeedKmh, avgSpeedKmh, movingTime, trailCount);

  /// Create a copy of ActivityStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActivityStatsImplCopyWith<_$ActivityStatsImpl> get copyWith =>
      __$$ActivityStatsImplCopyWithImpl<_$ActivityStatsImpl>(this, _$identity);
}

abstract class _ActivityStats extends ActivityStats {
  const factory _ActivityStats(
      {required final double totalDistanceKm,
      required final double totalVerticalDropM,
      required final double topSpeedKmh,
      required final double avgSpeedKmh,
      required final Duration movingTime,
      required final int trailCount}) = _$ActivityStatsImpl;
  const _ActivityStats._() : super._();

  @override
  double get totalDistanceKm;
  @override
  double get totalVerticalDropM;
  @override
  double get topSpeedKmh;
  @override
  double get avgSpeedKmh;
  @override
  Duration get movingTime;

  /// Distinct named trails touched during the activity (Engine 3).
  @override
  int get trailCount;

  /// Create a copy of ActivityStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActivityStatsImplCopyWith<_$ActivityStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
