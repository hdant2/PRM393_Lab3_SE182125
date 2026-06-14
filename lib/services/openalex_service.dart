import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/publication.dart';

/// Service chịu trách nhiệm giao tiếp với OpenAlex API
class OpenAlexService {

  /// Tìm kiếm các bài báo theo chủ đề
  ///
  /// Ví dụ:
  /// "Artificial Intelligence"
  /// "Blockchain"
  /// "Cybersecurity"
  Future<List<Publication>> searchPublications(String topic) async {

    // Encode keyword để URL hợp lệ
    // Ví dụ:
    // Artificial Intelligence
    // =>
    // Artificial%20Intelligence
    final encodedTopic =
        Uri.encodeComponent(topic);

    // Tạo URL gọi OpenAlex API
    //Hiện tại đang lấy 20 kết quả search đầu tiên
    final url = Uri.parse(
      'https://api.openalex.org/works?search=$encodedTopic&per-page=20',
    );

    // Gửi HTTP GET request
    final response = await http.get(url);

    // Kiểm tra request thành công
    if (response.statusCode == 200) {

      // Chuyển JSON String thành Dart Object
      final data =
          jsonDecode(response.body);

      // Lấy danh sách publications
      final List results =
          data['results'] ?? [];

      // Chuyển từng JSON thành Publication object
      return results
          .map(
            (item) =>
                Publication.fromJson(item),
          )
          .toList();
    }

    // Trường hợp API lỗi
    throw Exception(
      'Failed to load publications',
    );
  }
}