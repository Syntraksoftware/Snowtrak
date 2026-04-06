// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'segment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Segment {
  SegmentType get type => throw _privateConstructorUsedError;
  List<TrackPoint> get points => throw _privateConstructorUsedError;
  int get startIndex => throw _privateConstructorUsedError;
  int get endIndex => throw _privateConstructorUsedError;
  String? get trailName => throw _privateConstructorUsedError;
  String? get difficulty => throw _privateConstructorUsedError;

  /// Create a copy of Segment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SegmentCopyWith<Segment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SegmentCopyWith<$Res> {
  factory $SegmentCopyWith(Segment value, $Res Function(Segment) then) =
      _$SegmentCopyWithImpl<$Res, Segment>;
  @useResult
  $Res call(
      {SegmentType type,
      List<TrackPoint> points,
      int startIndex,
      int endIndex,
      String? trailName,
      String? difficulty});
}

/// @nodoc
class _$SegmentCopyWithImpl<$Res, $Val extends Segment>
    implements $SegmentCopyWith<$Res> {
  _$SegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Segment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? points = null,
    Object? startIndex = null,
    Object? endIndex = null,
    Object? trailName = freezed,
    Object? difficulty = freezed,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SegmentType,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as List<TrackPoint>,
      startIndex: null == startIndex
          ? _value.startIndex
          : startIndex // ignore: cast_nullable_to_non_nullable
              as int,
      endIndex: null == endIndex
          ? _value.endIndex
          : endIndex // ignore: cast_nullable_to_non_nullable
              as int,
      trailName: freezed == trailName
          ? _value.trailName
          : trailName // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SegmentImplCopyWith<$Res> implements $SegmentCopyWith<$Res> {
  factory _$$SegmentImplCopyWith(
          _$SegmentImpl value, $Res Function(_$SegmentImpl) then) =
      __$$SegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {SegmentType type,
      List<TrackPoint> points,
      int startIndex,
      int endIndex,
      String? trailName,
      String? difficulty});
}

/// @nodoc
class __$$SegmentImplCopyWithImpl<$Res>
    extends _$SegmentCopyWithImpl<$Res, _$SegmentImpl>
    implements _$$SegmentImplCopyWith<$Res> {
  __$$SegmentImplCopyWithImpl(
      _$SegmentImpl _value, $Res Function(_$SegmentImpl) _then)
      : super(_value, _then);

  /// Create a copy of Segment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? points = null,
    Object? startIndex = null,
    Object? endIndex = null,
    Object? trailName = freezed,
    Object? difficulty = freezed,
  }) {
    return _then(_$SegmentImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as SegmentType,
      points: null == points
          ? _value._points
          : points // ignore: cast_nullable_to_non_nullable
              as List<TrackPoint>,
      startIndex: null == startIndex
          ? _value.startIndex
          : startIndex // ignore: cast_nullable_to_non_nullable
              as int,
      endIndex: null == endIndex
          ? _value.endIndex
          : endIndex // ignore: cast_nullable_to_non_nullable
              as int,
      trailName: freezed == trailName
          ? _value.trailName
          : trailName // ignore: cast_nullable_to_non_nullable
              as String?,
      difficulty: freezed == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SegmentImpl extends _Segment with DiagnosticableTreeMixin {
  const _$SegmentImpl(
      {required this.type,
      required final List<TrackPoint> points,
      required this.startIndex,
      required this.endIndex,
      this.trailName,
      this.difficulty})
      : _points = points,
        super._();

  @override
  final SegmentType type;
  final List<TrackPoint> _points;
  @override
  List<TrackPoint> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  @override
  final int startIndex;
  @override
  final int endIndex;
  @override
  final String? trailName;
  @override
  final String? difficulty;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Segment(type: $type, points: $points, startIndex: $startIndex, endIndex: $endIndex, trailName: $trailName, difficulty: $difficulty)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Segment'))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('points', points))
      ..add(DiagnosticsProperty('startIndex', startIndex))
      ..add(DiagnosticsProperty('endIndex', endIndex))
      ..add(DiagnosticsProperty('trailName', trailName))
      ..add(DiagnosticsProperty('difficulty', difficulty));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SegmentImpl &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._points, _points) &&
            (identical(other.startIndex, startIndex) ||
                other.startIndex == startIndex) &&
            (identical(other.endIndex, endIndex) ||
                other.endIndex == endIndex) &&
            (identical(other.trailName, trailName) ||
                other.trailName == trailName) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      type,
      const DeepCollectionEquality().hash(_points),
      startIndex,
      endIndex,
      trailName,
      difficulty);

  /// Create a copy of Segment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SegmentImplCopyWith<_$SegmentImpl> get copyWith =>
      __$$SegmentImplCopyWithImpl<_$SegmentImpl>(this, _$identity);
}

abstract class _Segment extends Segment {
  const factory _Segment(
      {required final SegmentType type,
      required final List<TrackPoint> points,
      required final int startIndex,
      required final int endIndex,
      final String? trailName,
      final String? difficulty}) = _$SegmentImpl;
  const _Segment._() : super._();

  @override
  SegmentType get type;
  @override
  List<TrackPoint> get points;
  @override
  int get startIndex;
  @override
  int get endIndex;
  @override
  String? get trailName;
  @override
  String? get difficulty;

  /// Create a copy of Segment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SegmentImplCopyWith<_$SegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
