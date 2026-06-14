import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/publication.dart';
import '../providers/publication_provider.dart';

import '../widgets/dashboard_card.dart';

import 'trend_screen.dart';
import 'top_papers_screen.dart';
import 'top_journals_screen.dart';
import 'top_authors_screen.dart';
import 'detail_screen.dart';
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    // =====================================================
    // STEP 1: Lấy dữ liệu từ Provider
    // =====================================================
    final provider =
        context.watch<PublicationProvider>();

    final publications =
        provider.publications;

    final topic =
        provider.currentTopic;

    // =====================================================
    // STEP 2: Tính toán các chỉ số
    // =====================================================
    final totalPublications =
        publications.length;

    final averageCitation =
        _getAverageCitation(publications);

    final mostActiveYear =
        _getMostActiveYear(publications);

    final topJournal =
        _getTopJournal(publications);

    final topAuthor =
        _getTopAuthor(publications);

    final topPaper =
        _getMostInfluentialPaperObject(
      publications,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Research Dashboard',
        ),
      ),

      body: publications.isEmpty
          ? const Center(
              child: Text(
                'Please search a topic first.',
              ),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  // =====================================================
                  // TOPIC SUMMARY
                  // =====================================================
                  Card(
                    color:
                        Colors.deepPurple.shade50,

                    elevation: 5,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: ListTile(
                      leading: const Icon(
                        Icons.dashboard,
                        size: 40,
                        color:
                            Colors.deepPurple,
                      ),

                      title: Text(
                        'Topic: $topic',

                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      subtitle: Text(
                        '$totalPublications publications analyzed',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =====================================================
                  // SECTION TITLE
                  // =====================================================
                  // =====================================================
// RESEARCH INSIGHTS
// =====================================================

const Text(
  'Research Insights',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

// =====================================================
// DASHBOARD GRID
// Mobile: 2 cột x 3 hàng
// =====================================================

GridView.count(
  shrinkWrap: true,

  // Không cho GridView tự scroll
  physics: const NeverScrollableScrollPhysics(),

  // 2 card trên mỗi hàng
  crossAxisCount: 2,

  // Khoảng cách ngang
  crossAxisSpacing: 12,

  // Khoảng cách dọc
  mainAxisSpacing: 12,

  // Tỉ lệ card
  childAspectRatio: 1.3,

  children: [

    // =====================================================
    // TOTAL PUBLICATIONS
    // =====================================================

    DashboardCard(
      title: 'Papers',
      value: totalPublications.toString(),
      icon: Icons.article,
      color: Colors.blue,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TopPapersScreen(),
          ),
        );
      },
    ),

    // =====================================================
    // AVERAGE CITATIONS
    // =====================================================

    DashboardCard(
      title: 'Avg Citation',
      value: averageCitation.toStringAsFixed(0),
      icon: Icons.star,
      color: Colors.orange,
    ),

    // =====================================================
    // TREND ANALYSIS
    // =====================================================

    DashboardCard(
      title: 'Trend',
      value: mostActiveYear,
      icon: Icons.show_chart,
      color: Colors.green,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TrendScreen(),
          ),
        );
      },
    ),

    // =====================================================
    // TOP AUTHOR
    // =====================================================

    DashboardCard(
      title: 'Author',
      value: topAuthor,
      icon: Icons.person,
      color: Colors.purple,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TopAuthorsScreen(),
          ),
        );
      },
    ),

    // =====================================================
    // TOP JOURNAL
    // =====================================================

    DashboardCard(
      title: 'Journal',
      value: topJournal,
      icon: Icons.menu_book,
      color: Colors.teal,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TopJournalsScreen(),
          ),
        );
      },
    ),

    // =====================================================
    // MOST INFLUENTIAL PAPER
    // =====================================================

    DashboardCard(
      title: 'Top Paper',
      value: topPaper.citations.toString(),
      icon: Icons.emoji_events,
      color: Colors.amber,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              publication: topPaper,
            ),
          ),
        );
      },
    ),
  ],
),
                ],
              ),
            ),
    );
  }


  // =======================================================
  // HELPER METHODS
  // =======================================================

  double _getAverageCitation(
    List<Publication> publications,
  ) {
    if (publications.isEmpty) {
      return 0;
    }

    final total = publications.fold(
      0,
      (sum, publication) =>
          sum + publication.citations,
    );

    return total / publications.length;
  }

  String _getMostActiveYear(
    List<Publication> publications,
  ) {
    final Map<int, int> yearCount = {};

    for (final publication
        in publications) {
      if (publication.year == 0) {
        continue;
      }

      yearCount[publication.year] =
          (yearCount[
                      publication.year] ??
                  0) +
              1;
    }

    if (yearCount.isEmpty) {
      return 'N/A';
    }

    final topYear =
        yearCount.entries.reduce(
      (a, b) =>
          a.value >= b.value
              ? a
              : b,
    );

    return '${topYear.key}';
  }

  String _getTopJournal(
    List<Publication> publications,
  ) {
    final Map<String, int>
        journalCount = {};

    for (final publication
        in publications) {
      if (publication.journal ==
          'Unknown Journal') {
        continue;
      }

      journalCount[
              publication.journal] =
          (journalCount[
                      publication
                          .journal] ??
                  0) +
              1;
    }

    if (journalCount.isEmpty) {
      return 'N/A';
    }

    return journalCount.entries
        .reduce(
          (a, b) =>
              a.value >= b.value
                  ? a
                  : b,
        )
        .key;
  }

  String _getTopAuthor(
    List<Publication> publications,
  ) {
    final Map<String, int>
        authorCount = {};

    for (final publication
        in publications) {
      for (final author
          in publication.authors) {
        if (author ==
            'Unknown Author') {
          continue;
        }

        authorCount[author] =
            (authorCount[author] ??
                    0) +
                1;
      }
    }

    if (authorCount.isEmpty) {
      return 'N/A';
    }

    return authorCount.entries
        .reduce(
          (a, b) =>
              a.value >= b.value
                  ? a
                  : b,
        )
        .key;
  }

  Publication
      _getMostInfluentialPaperObject(
    List<Publication> publications,
  ) {
    return publications.reduce(
      (a, b) =>
          a.citations >= b.citations
              ? a
              : b,
    );
  }
}