// =============================================================================
// openalex_exception.dart — LỖI API
// =============================================================================
// OpenAlexService._mapHttpError() tạo exception → provider hiển thị trên UI
// =============================================================================

/// Lỗi gọi OpenAlex — PublicationProvider._mapError() hiển thị message này
class OpenAlexException implements Exception {
  final String message;
  final int? statusCode;

  OpenAlexException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
