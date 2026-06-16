/// Lỗi gọi OpenAlex API — message thân thiện cho UI
class OpenAlexException implements Exception {
  final String message;
  final int? statusCode;

  OpenAlexException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
