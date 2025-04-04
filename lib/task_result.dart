
sealed class TaskResult<T> {}

class Success<T> extends TaskResult<T> {
  final T data;
  Success(this.data);
}

class Error<T> extends TaskResult<T> {
  final Exception errorMessage;
  Error(this.errorMessage);
}
