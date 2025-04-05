
sealed class TaskResult<T> {}

class Success<T> extends TaskResult<T> {
  final T data;
  Success(this.data);

  @override
  String toString() => "$data";
}

class Error<T> extends TaskResult<T> {
  final Exception errorMessage;
  Error(this.errorMessage);

  @override
  String toString() => "$errorMessage";
}
