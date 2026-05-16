import 'package:syntrak/core/errors/app_error.dart';

/// Sentinel for successful operations with no payload ([deleteActivity], etc.).
final class Unit {
  const Unit._();
  static const unit = Unit._();
}

/// Unified success/failure for async service calls (avoids silent try/catch drift).
sealed class AppResult<T> {
  const AppResult();

  bool get isSuccess => this is AppSuccess<T>;
  bool get isFailure => this is AppFailure<T>;
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  final T value;
}

final class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.error);

  final AppError error;
}

extension AppResultX<T> on AppResult<T> {
  R fold<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      AppSuccess(:final value) => success(value),
      AppFailure(:final error) => failure(error),
    };
  }
}
