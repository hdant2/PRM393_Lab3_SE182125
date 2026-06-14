import 'package:flutter/material.dart';

import '../model/publication.dart';

import '../screens/detail_screen.dart';

/// Widget hiển thị thông tin tóm tắt của một bài báo
class PublicationCard extends StatelessWidget {

  // Publication được truyền từ SearchScreen
  final Publication publication;

  const PublicationCard({
    super.key,
    required this.publication,
  });

  @override
  Widget build(BuildContext context) {

    return Card(

      // Khoảng cách giữa các card
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      // Đổ bóng cho card
      elevation: 3,

      child: ListTile(

        // =====================================================
        // TITLE
        // =====================================================

        title: Text(
          publication.title,

          // Giới hạn tối đa 2 dòng
          maxLines: 2,

          overflow:
              TextOverflow.ellipsis,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        // =====================================================
        // PUBLICATION INFORMATION
        // =====================================================

        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 8,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              // Publication Year
              Text(
                'Year: ${publication.year}',
              ),

              // Citation Count
              Text(
                'Citations: ${publication.citations}',
              ),

              // Journal Name
              Text(
                'Journal: ${publication.journal}',
              ),
            ],
          ),
        ),

        // =====================================================
        // DETAIL ICON
        // =====================================================

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),

        // =====================================================
        // NAVIGATION TO DETAIL SCREEN
        // =====================================================

        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailScreen(
        publication: publication,
      ),
    ),
  );
},
      ),
    );
  }
}