// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'elevation_chart_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ElevationChartData {
  List<FlSpot> get spots => throw _privateConstructorUsedError;
  List<({double end, double start})> get liftBandRanges =>
      throw _privateConstructorUsedError;
  double get minElevM => throw _privateConstructorUsedError;
  double get maxElevM => throw _privateConstructorUsedError;

  /// Create a copy of ElevationChartData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ElevationChartDataCopyWith<ElevationChartData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ElevationChartDataCopyWith<$Res> {
  factory $ElevationChartDataCopyWith(
          ElevationChartData value, $Res Function(ElevationChartData) then) =
      _$ElevationChartDataCopyWithImpl<$Res, ElevationChartData>;
  @useResult
  $Res call(
      {List<FlSpot> spots,
      List<({double end, double start})> liftBandRanges,
      double minElevM,
      double maxElevM});
}

/// @nodoc
class _$ElevationChartDataCopyWithImpl<$Res, $Val extends ElevationChartData>
    implements $ElevationChartDataCopyWith<$Res> {
  _$ElevationChartDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ElevationChartData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spots = null,
    Object? liftBandRanges = null,
    Object? minElevM = null,
    Object? maxElevM = null,
  }) {
    return _then(_value.copyWith(
      spots: null == spots
          ? _value.spots
          : spots // ignore: cast_nullable_to_non_nullable
              as List<FlSpot>,
      liftBandRanges: null == liftBandRanges
          ? _value.liftBandRanges
          : liftBandRanges // ignore: cast_nullable_to_non_nullable
              as List<({double end, double start})>,
      minElevM: null == minElevM
          ? _value.minElevM
          : minElevM // ignore: cast_nullable_to_non_nullable
              as double,
      maxElevM: null == maxElevM
          ? _value.maxElevM
          : maxElevM // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ElevationChartDataImplCopyWith<$Res>
    implements $ElevationChartDataCopyWith<$Res> {
  factory _$$ElevationChartDataImplCopyWith(_$ElevationChartDataImpl value,
          $Res Function(_$ElevationChartDataImpl) then) =
      __$$ElevationChartDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<FlSpot> spots,
      List<({double end, double start})> liftBandRanges,
      double minElevM,
      double maxElevM});
}

/// @nodoc
class __$$ElevationChartDataImplCopyWithImpl<$Res>
    extends _$ElevationChartDataCopyWithImpl<$Res, _$ElevationChartDataImpl>
    implements _$$ElevationChartDataImplCopyWith<$Res> {
  __$$ElevationChartDataImplCopyWithImpl(_$ElevationChartDataImpl _value,
      $Res Function(_$ElevationChartDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ElevationChartData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? spots = null,
    Object? liftBandRanges = null,
    Object? minElevM = null,
    Object? maxElevM = null,
  }) {
    return _then(_$ElevationChartDataImpl(
      spots: null == spots
          ? _value._spots
          : spots // ignore: cast_nullable_to_non_nullable
              as List<FlSpot>,
      liftBandRanges: null == liftBandRanges
          ? _value._liftBandRanges
          : liftBandRanges // ignore: cast_nullable_to_non_nullable
              as List<({double end, double start})>,
      minElevM: null == minElevM
          ? _value.minElevM
          : minElevM // ignore: cast_nullable_to_non_nullable
              as double,
      maxElevM: null == maxElevM
          ? _value.maxElevM
          : maxElevM // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$ElevationChartDataImpl extends _ElevationChartData
    with DiagnosticableTreeMixin {
  const _$ElevationChartDataImpl(
      {required final List<FlSpot> spots,
      required final List<({double end, double start})> liftBandRanges,
      required this.minElevM,
      required this.maxElevM})
      : _spots = spots,
        _liftBandRanges = liftBandRanges,
        super._();

  final List<FlSpot> _spots;
  @override
  List<FlSpot> get spots {
    if (_spots is EqualUnmodifiableListView) return _spots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_spots);
  }

  final List<({double end, double start})> _liftBandRanges;
  @override
  List<({double end, double start})> get liftBandRanges {
    if (_liftBandRanges is EqualUnmodifiableListView) return _liftBandRanges;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_liftBandRanges);
  }

  @override
  final double minElevM;
  @override
  final double maxElevM;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ElevationChartData(spots: $spots, liftBandRanges: $liftBandRanges, minElevM: $minElevM, maxElevM: $maxElevM)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ElevationChartData'))
      ..add(DiagnosticsProperty('spots', spots))
      ..add(DiagnosticsProperty('liftBandRanges', liftBandRanges))
      ..add(DiagnosticsProperty('minElevM', minElevM))
      ..add(DiagnosticsProperty('maxElevM', maxElevM));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ElevationChartDataImpl &&
            const DeepCollectionEquality().equals(other._spots, _spots) &&
            const DeepCollectionEquality()
                .equals(other._liftBandRanges, _liftBandRanges) &&
            (identical(other.minElevM, minElevM) ||
                other.minElevM == minElevM) &&
            (identical(other.maxElevM, maxElevM) ||
                other.maxElevM == maxElevM));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_spots),
      const DeepCollectionEquality().hash(_liftBandRanges),
      minElevM,
      maxElevM);

  /// Create a copy of ElevationChartData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ElevationChartDataImplCopyWith<_$ElevationChartDataImpl> get copyWith =>
      __$$ElevationChartDataImplCopyWithImpl<_$ElevationChartDataImpl>(
          this, _$identity);
}

abstract class _ElevationChartData extends ElevationChartData {
  const factory _ElevationChartData(
      {required final List<FlSpot> spots,
      required final List<({double end, double start})> liftBandRanges,
      required final double minElevM,
      required final double maxElevM}) = _$ElevationChartDataImpl;
  const _ElevationChartData._() : super._();

  @override
  List<FlSpot> get spots;
  @override
  List<({double end, double start})> get liftBandRanges;
  @override
  double get minElevM;
  @override
  double get maxElevM;

  /// Create a copy of ElevationChartData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ElevationChartDataImplCopyWith<_$ElevationChartDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
