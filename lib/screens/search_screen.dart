import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
import '../widgets/publication_card.dart';
import 'dashboard_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() =>
      _SearchScreenState();
}

class _SearchScreenState
    extends State<SearchScreen> {

  // =====================================================
  // Controller lấy dữ liệu từ TextField
  // =====================================================
  final TextEditingController
      _searchController =
          TextEditingController();

  /// Thực hiện tìm kiếm
  Future<void> _search() async {

    // =====================================================
    // Lấy topic người dùng nhập
    // =====================================================
    final topic =
        _searchController.text.trim();

    // =====================================================
    // Validate dữ liệu
    // =====================================================
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a research topic',
          ),
        ),
      );
      return;
    }

    // =====================================================
    // Gọi OpenAlex API
    // =====================================================
    await context
        .read<PublicationProvider>()
        .searchPublications(topic);
  }

  @override
  Widget build(BuildContext context) {

    final provider =
        context.watch<PublicationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journal Trend Analyzer',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            // =====================================================
            // SEARCH BOX
            // =====================================================
            TextField(
              controller:
                  _searchController,

              decoration:
                  const InputDecoration(
                labelText:
                    'Research Topic',

                hintText:
                    'Example: Artificial Intelligence',

                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // =====================================================
            // SEARCH BUTTON
            // =====================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed:
                    provider.isLoading
                        ? null
                        : _search,

                child:
                    const Text('Search'),
              ),
            ),

            const SizedBox(height: 16),

            // =====================================================
            // DASHBOARD ENTRY CARD
            // Chỉ hiện sau khi search thành công
            // =====================================================
            if (provider
                .publications
                .isNotEmpty)

              Card(
                elevation: 6,
                color:
                    Colors.deepPurple.shade50,

                child: ListTile(

                  leading: const Icon(
                    Icons.dashboard,
                    size: 40,
                    color:
                        Colors.deepPurple,
                  ),

                  title: const Text(
                    'Research Dashboard',

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    '${provider.publications.length} publications analyzed',
                  ),

                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const DashboardScreen(),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),

            // =====================================================
            // LOADING
            // =====================================================
            if (provider.isLoading)
              const CircularProgressIndicator(),

            // =====================================================
            // ERROR
            // =====================================================
            if (provider.errorMessage != null)
              Text(
                provider.errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),

            // =====================================================
            // PUBLICATION LIST
            // =====================================================
            Expanded(
              child: ListView.builder(
                itemCount: provider
                    .publications.length,

                itemBuilder:
                    (context, index) {

                  final publication =
                      provider.publications[
                          index];

                  return PublicationCard(
                    publication:
                        publication,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}