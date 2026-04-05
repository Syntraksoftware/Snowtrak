// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'processed_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProcessedTrack {
  String get id =>
      throw _privateConstructorUsedError; //UUID/ server generated id for the track
  List<TrackPoint> get points => throw _privateConstructorUsedError;
  DateTime get recordedAt => throw _privateConstructorUsedError;
  SourceType get sourceType => throw _privateConstructorUsedError;

  /// Create a copy of ProcessedTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProcessedTrackCopyWith<ProcessedTrack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProcessedTrackCopyWith<$Res> {
  factory $ProcessedTrackCopyWith(
          ProcessedTrack value, $Res Function(ProcessedTrack) then) =
      _$ProcessedTrackCopyWithImpl<$Res, ProcessedTrack>;
  @useResult
  $Res call(
      {String id,
      List<TrackPoint> points,
      DateTime recordedAt,
      SourceType sourceType});
}

/// @nodoc
class _$ProcessedTrackCopyWithImpl<$Res, $Val extends ProcessedTrack>
    implements $ProcessedTrackCopyWith<$Res> {
  _$ProcessedTrackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProcessedTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? points = null,
    Object? recordedAt = null,
    Object? sourceType = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      points: null == points
          ? _value.points
          : points // ignore: cast_nullable_to_non_nullable
              as List<TrackPoint>,
      recordedAt: null == recordedAt
          ? _value.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sourceType: null == sourceType
          ? _value.sourceType
          : sourceType // ignore: cast_nullable_to_non_nullable
              as SourceType,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProcessedTrackImplCopyWith<$Res>
    implements $ProcessedTrackCopyWith<$Res> {
  factory _$$ProcessedTrackImplCopyWith(_$ProcessedTrackImpl value,
          $Res Function(_$ProcessedTrackImpl) then) =
      __$$ProcessedTrackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      List<TrackPoint> points,
      DateTime recordedAt,
      SourceType sourceType});
}

/// @nodoc
class __$$ProcessedTrackImplCopyWithImpl<$Res>
    extends _$ProcessedTrackCopyWithImpl<$Res, _$ProcessedTrackImpl>
    implements _$$ProcessedTrackImplCopyWith<$Res> {
  __$$ProcessedTrackImplCopyWithImpl(
      _$ProcessedTrackImpl _value, $Res Function(_$ProcessedTrackImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProcessedTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? points = null,
    Object? recordedAt = null,
    Object? sourceType = null,
  }) {
    return _then(_$ProcessedTrackImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      points: null == points
          ? _value._points
          : points // ignore: cast_nullable_to_non_nullable
              as List<TrackPoint>,
      recordedAt: null == recordedAt
          ? _value.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sourceType: null == sourceType
          ? _value.sourceType
          : sourceType // ignore: cast_nullable_to_non_nullable
              as SourceType,
    ));
  }
}

/// @nodoc

class _$ProcessedTrackImpl extends _ProcessedTrack
    with DiagnosticableTreeMixin {
  const _$ProcessedTrackImpl(
      {required this.id,
      required final List<TrackPoint> points,
      required this.recordedAt,
      required this.sourceType})
      : _points = points,
        super._();

  @override
  final String id;
//UUID/ server generated id for the track
  final List<TrackPoint> _points;
//UUID/ server generated id for the track
  @override
  List<TrackPoint> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  @override
  final DateTime recordedAt;
  @override
  final SourceType sourceType;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ProcessedTrack(id: $id, points: $points, recordedAt: $recordedAt, sourceType: $sourceType)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ProcessedTrack'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('points', points))
      ..add(DiagnosticsProperty('recordedAt', recordedAt))
      ..add(DiagnosticsProperty('sourceType', sourceType));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProcessedTrackImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._points, _points) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id,
      const DeepCollectionEquality().hash(_points), recordedAt, sourceType);

  /// Create a copy of ProcessedTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProcessedTrackImplCopyWith<_$ProcessedTrackImpl> get copyWith =>
      __$$ProcessedTrackImplCopyWithImpl<_$ProcessedTrackImpl>(
          this, _$identity);
}

abstract class _ProcessedTrack extends ProcessedTrack {
  const factory _ProcessedTrack(
      {required final String id,
      required final List<TrackPoint> points,
      required final DateTime recordedAt,
      required final SourceType sourceType}) = _$ProcessedTrackImpl;
  const _ProcessedTrack._() : super._();

  @override
  String get id; //UUID/ server generated id for the track
  @override
  List<TrackPoint> get points;
  @override
  DateTime get recordedAt;
  @override
  SourceType get sourceType;

  /// Create a copy of ProcessedTrack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProcessedTrackImplCopyWith<_$ProcessedTrackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
