import 'package:flutter/material.dart';

import '../model/publication.dart';
import '../services/openalex_service.dart';

class PublicationProvider extends ChangeNotifier {
  final OpenAlexService _openAlexService = OpenAlexService();

  String currentTopic = '';
  // Danh sách bài báo lấy từ OpenAlex
  List<Publication> publications = [];

  // Trạng thái loading khi đang gọi API
  bool isLoading = false;

  // Lưu lỗi nếu gọi API thất bại
  String? errorMessage;

  Future<void> searchPublications(String topic) async {
    // Bắt đầu loading
    isLoading = true;
    currentTopic = topic;
    errorMessage = null;
    notifyListeners();

    try {
      // Gọi service để lấy dữ liệu
      publications = await _openAlexService.searchPublications(topic);
    } catch (e) {
      // Nếu lỗi thì lưu message
      errorMessage = e.toString();
    } finally {
      // Kết thúc loading
      isLoading = false;
      notifyListeners();
    }
  }
}