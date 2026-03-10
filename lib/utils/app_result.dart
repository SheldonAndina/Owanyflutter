/// Professional error/result handling using Either/Result pattern
/// Provides functional approach to error handling
library;

/// Represents a value that is either a [Success] or a [Failure]
abstract class Result<T> {
  /// Execute a function based on success or failure
  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess);

  /// Map the success value to another type
  Result<U> map<U>(U Function(T data) transformer);

  /// Map the failure to another type
  Result<T> mapError(Failure Function(Failure failure) transformer);

  /// Get the value or null
  T? getOrNull();

  /// Get the error or null
  Failure? getErrorOrNull();

  /// Check if result is success
  bool get isSuccess;

  /// Check if result is failure
  bool get isFailure;
}

/// Success result containing data
class Success<T> implements Result<T> {
  final T data;

  Success(this.data);

  @override
  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess) {
    return onSuccess(data);
  }

  @override
  Result<U> map<U>(U Function(T data) transformer) {
    try {
      return Success(transformer(data));
    } catch (e, stackTrace) {
      return Failure(message: 'Error mapping success value: $e', error: e, stackTrace: stackTrace);
    }
  }

  @override
  Result<T> mapError(Failure Function(Failure failure) transformer) {
    return this;
  }

  @override
  T? getOrNull() => data;

  @override
  Failure? getErrorOrNull() => null;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  String toString() => 'Success($data)';
}

/// Failure result containing error information
class Failure<T> implements Result<T> {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final int? statusCode;
  final String? errorCode;

  Failure({required this.message, this.error, this.stackTrace, this.statusCode, this.errorCode});

  @override
  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess) {
    return onFailure(this);
  }

  @override
  Result<U> map<U>(U Function(T data) transformer) {
    return Failure<U>(
      message: message,
      error: error,
      stackTrace: stackTrace,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  @override
  Result<T> mapError(Failure Function(Failure failure) transformer) {
    final transformed = transformer(this);
    if (transformed is Success) {
      return Success<T>((transformed as Success).data);
    } else {
      return Failure<T>(message: transformed.message, errorCode: transformed.errorCode);
    }
  }

  @override
  T? getOrNull() => null;

  @override
  Failure? getErrorOrNull() => this;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  String toString() => 'Failure($message, statusCode: $statusCode, errorCode: $errorCode)';
}

/// Either monad - represents a value that is either Left (failure) or Right (success)
abstract class Either<L, R> {
  /// Execute a function based on left or right
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight);

  /// Map the right value
  Either<L, U> map<U>(U Function(R right) transformer);

  /// Map the left value
  Either<U, R> mapLeft<U>(U Function(L left) transformer);

  /// Bind/FlatMap for monadic operations
  Either<L, U> flatMap<U>(Either<L, U> Function(R right) transformer);

  /// Get right value or null
  R? getRightOrNull();

  /// Get left value or null
  L? getLeftOrNull();

  /// Check if either is right
  bool get isRight;

  /// Check if either is left
  bool get isLeft;
}

/// Left side of Either - represents failure/error
class Left<L, R> implements Either<L, R> {
  final L value;

  Left(this.value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return onLeft(value);
  }

  @override
  Either<L, U> map<U>(U Function(R right) transformer) {
    return Left(value);
  }

  @override
  Either<U, R> mapLeft<U>(U Function(L left) transformer) {
    return Left(transformer(value));
  }

  @override
  Either<L, U> flatMap<U>(Either<L, U> Function(R right) transformer) {
    return Left(value);
  }

  @override
  R? getRightOrNull() => null;

  @override
  L? getLeftOrNull() => value;

  @override
  bool get isRight => false;

  @override
  bool get isLeft => true;

  @override
  String toString() => 'Left($value)';
}

/// Right side of Either - represents success
class Right<L, R> implements Either<L, R> {
  final R value;

  Right(this.value);

  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) {
    return onRight(value);
  }

  @override
  Either<L, U> map<U>(U Function(R right) transformer) {
    try {
      return Right(transformer(value));
    } catch (e) {
      return Left(e as L);
    }
  }

  @override
  Either<U, R> mapLeft<U>(U Function(L left) transformer) {
    return Right(value);
  }

  @override
  Either<L, U> flatMap<U>(Either<L, U> Function(R right) transformer) {
    return transformer(value);
  }

  @override
  R? getRightOrNull() => value;

  @override
  L? getLeftOrNull() => null;

  @override
  bool get isRight => true;

  @override
  bool get isLeft => false;

  @override
  String toString() => 'Right($value)';
}
