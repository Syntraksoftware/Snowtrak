// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'run_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RunSummary {
  double get distanceKm => throw _privateConstructorUsedError;
  double get verticalDropM => throw _privateConstructorUsedError;
  double get topSpeedKmh => throw _privateConstructorUsedError;
  double get avgSpeedKmh => throw _privateConstructorUsedError;
  Duration get movingTime => throw _privateConstructorUsedError;
  String? get trailName => throw _privateConstructorUsedError;

  /// Create a copy of RunSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RunSummaryCopyWith<RunSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RunSummaryCopyWith<$Res> {
  factory $RunSummaryCopyWith(
          RunSummary value, $Res Function(RunSummary) then) =
      _$RunSummaryCopyWithImpl<$Res, RunSummary>;
  @useResult
  $Res call(
      {double distanceKm,
      double verticalDropM,
      double topSpeedKmh,
      double avgSpeedKmh,
      Duration movingTime,
      String? trailName});
}

/// @nodoc
class _$RunSummaryCopyWithImpl<$Res, $Val extends RunSummary>
    implements $RunSummaryCopyWith<$Res> {
  _$RunSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RunSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? distanceKm = null,
    Object? verticalDropM = null,
    Object? topSpeedKmh = null,
    Object? avgSpeedKmh = null,
    Object? movingTime = null,
    Object? trailName = freezed,
  }) {
    return _then(_value.copyWith(
      distanceKm: null == distanceKm
          ? _value.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      verticalDropM: null == verticalDropM
          ? _value.verticalDropM
          : verticalDropM // ignore: cast_nullable_to_non_nullable
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
      trailName: freezed == trailName
          ? _value.trailName
          : trailName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RunSummaryImplCopyWith<$Res>
    implements $RunSummaryCopyWith<$Res> {
  factory _$$RunSummaryImplCopyWith(
          _$RunSummaryImpl value, $Res Function(_$RunSummaryImpl) then) =
      __$$RunSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double distanceKm,
      double verticalDropM,
      double topSpeedKmh,
      double avgSpeedKmh,
      Duration movingTime,
      String? trailName});
}

/// @nodoc
class __$$RunSummaryImplCopyWithImpl<$Res>
    extends _$RunSummaryCopyWithImpl<$Res, _$RunSummaryImpl>
    implements _$$RunSummaryImplCopyWith<$Res> {
  __$$RunSummaryImplCopyWithImpl(
      _$RunSummaryImpl _value, $Res Function(_$RunSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of RunSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? distanceKm = null,
    Object? verticalDropM = null,
    Object? topSpeedKmh = null,
    Object? avgSpeedKmh = null,
    Object? movingTime = null,
    Object? trailName = freezed,
  }) {
    return _then(_$RunSummaryImpl(
      distanceKm: null == distanceKm
          ? _value.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      verticalDropM: null == verticalDropM
          ? _value.verticalDropM
          : verticalDropM // ignore: cast_nullable_to_non_nullable
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
      trailName: freezed == trailName
          ? _value.trailName
          : trailName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$RunSummaryImpl extends _RunSummary with DiagnosticableTreeMixin {
  const _$RunSummaryImpl(
      {required this.distanceKm,
      required this.verticalDropM,
      required this.topSpeedKmh,
      required this.avgSpeedKmh,
      required this.movingTime,
      this.trailName})
      : super._();

  @override
  final double distanceKm;
  @override
  final double verticalDropM;
  @override
  final double topSpeedKmh;
  @override
  final double avgSpeedKmh;
  @override
  final Duration movingTime;
  @override
  final String? trailName;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RunSummary(distanceKm: $distanceKm, verticalDropM: $verticalDropM, topSpeedKmh: $topSpeedKmh, avgSpeedKmh: $avgSpeedKmh, movingTime: $movingTime, trailName: $trailName)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'RunSummary'))
      ..add(DiagnosticsProperty('distanceKm', distanceKm))
      ..add(DiagnosticsProperty('verticalDropM', verticalDropM))
      ..add(DiagnosticsProperty('topSpeedKmh', topSpeedKmh))
      ..add(DiagnosticsProperty('avgSpeedKmh', avgSpeedKmh))
      ..add(DiagnosticsProperty('movingTime', movingTime))
      ..add(DiagnosticsProperty('trailName', trailName));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RunSummaryImpl &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm) &&
            (identical(other.verticalDropM, verticalDropM) ||
                other.verticalDropM == verticalDropM) &&
            (identical(other.topSpeedKmh, topSpeedKmh) ||
                other.topSpeedKmh == topSpeedKmh) &&
            (identical(other.avgSpeedKmh, avgSpeedKmh) ||
                other.avgSpeedKmh == avgSpeedKmh) &&
            (identical(other.movingTime, movingTime) ||
                other.movingTime == movingTime) &&
            (identical(other.trailName, trailName) ||
                other.trailName == trailName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, distanceKm, verticalDropM,
      topSpeedKmh, avgSpeedKmh, movingTime, trailName);

  /// Create a copy of RunSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RunSummaryImplCopyWith<_$RunSummaryImpl> get copyWith =>
      __$$RunSummaryImplCopyWithImpl<_$RunSummaryImpl>(this, _$identity);
}

abstract class _RunSummary extends RunSummary {
  const factory _RunSummary(
      {required final double distanceKm,
      required final double verticalDropM,
      required final double topSpeedKmh,
      required final double avgSpeedKmh,
      required final Duration movingTime,
      final String? trailName}) = _$RunSummaryImpl;
  const _RunSummary._() : super._();

  @override
  double get distanceKm;
  @override
  double get verticalDropM;
  @override
  double get topSpeedKmh;
  @override
  double get avgSpeedKmh;
  @override
  Duration get movingTime;
  @override
  String? get trailName;

  /// Create a copy of RunSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RunSummaryImplCopyWith<_$RunSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
