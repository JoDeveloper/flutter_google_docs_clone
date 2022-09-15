// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';

@sealed
abstract class Result<S, E> {
  const Result();

  factory Result.tryCatch(S Function() run, E Function(Object o, StackTrace s) onError) {
    try {
      return Success(run());
    } catch (e, s) {
      return Error(onError(e, s));
    }
  }
  dynamic get();

  S? getSuccess();

  E? getError();

  bool isError();

  bool isSuccess();

  W when<W>(
    W Function(S success) whenSuccess,
    W Function(E error) whenError,
  );
}

@immutable
class Success<S, E> implements Result<S, E> {
  const Success(
    this._success,
  );

  final S _success;

  @override
  S get() {
    return _success;
  }

  @override
  bool isError() => false;

  @override
  bool isSuccess() => true;

  @override
  int get hashCode => _success.hashCode;

  @override
  bool operator ==(Object other) => other is Success && other._success == _success;

  @override
  W when<W>(
    W Function(S success) whenSuccess,
    W Function(E error) whenError,
  ) {
    return whenSuccess(_success);
  }

  @override
  E? getError() => null;

  @override
  S? getSuccess() => _success;
}

@immutable
class Error<S, E> implements Result<S, E> {
  const Error(this._error);

  final E _error;

  @override
  E get() {
    return _error;
  }

  @override
  bool isError() => true;

  @override
  bool isSuccess() => false;

  @override
  int get hashCode => _error.hashCode;

  @override
  bool operator ==(Object other) => other is Error && other._error == _error;

  @override
  W when<W>(
    W Function(S succcess) whenSuccess,
    W Function(E error) whenError,
  ) {
    return whenError(_error);
  }

  @override
  E? getError() => _error;

  @override
  S? getSuccess() => null;
}

class SuccessResult {
  const SuccessResult._internal();
}

const success = SuccessResult._internal();
