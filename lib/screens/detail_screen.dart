import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/openalex_ranked_entity.dart';
import '../models/publication.dart';
import '../models/publication_author.dart';
import '../providers/publication_provider.dart';
import '../theme/app_theme.dart';
import '../utils/count_format.dart';
import 'author_detail_screen.dart';

// =============================================================================
// detail_screen.dart — CHI TIẾT MỘT BÀI BÁO
// =============================================================================
// Abstract, authors (tap → AuthorDetail), DOI copy, read links, related works.
// =============================================================================

class DetailScreen extends StatefulWidget {
  final Publication publication;

  const DetailScreen({
    super.key,
    required this.publication,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  static const _authorPreviewCount = 3;

  bool _expandedAbstract = false;
  bool _expandedAuthors = false;
  List<Publication> _relatedWorks = [];
  bool _loadingRelated = false;

  @override
  void initState() {
    super.initState();
    _loadRelatedWorks();
  }

  Future<void> _loadRelatedWorks() async {
    final publication = widget.publication;
    if (publication.relatedWorkIds.isEmpty) return;

    setState(() => _loadingRelated = true);

    try {
      final provider = context.read<PublicationProvider>();
      final related = await provider.loadRelatedWorks(publication);
      if (!mounted) return;
      setState(() {
        _relatedWorks = related;
        _loadingRelated = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRelated = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Future<void> _copyDoi(Publication publication) async {
    final text = publication.displayDoi;
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('DOI copied')),
    );
  }

  void _openAuthor(PublicationAuthor author) {
    if (!author.hasOpenAlexId) return;

    final provider = context.read<PublicationProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthorDetailScreen(
          author: OpenAlexRankedEntity(
            id: author.id,
            name: author.name,
            count: 0,
          ),
          provider: provider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
    final influential = publication.citations >= 10000;
    final authors = publication.authorEntries;
    final hasManyAuthors = authors.length > _authorPreviewCount;
    final visibleAuthors = _expandedAuthors || !hasManyAuthors
        ? authors
        : authors.take(_authorPreviewCount).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (publication.hasReadLink)
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              tooltip: 'Read paper',
              onPressed: () => _openUrl(publication.readUrl!),
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: publication.hasReadLink
                ? () => _openUrl(publication.readUrl!)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              publication.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              formatOpenAlexCount(publication.citations),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Citations',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (influential) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Highly Influential',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (publication.hasReadLink) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openUrl(publication.readUrl!),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(
                    publication.openAccessUrl != null
                        ? 'Read paper (Open Access)'
                        : 'Read paper',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _LinksSection(
              publication: publication,
              onOpenUrl: _openUrl,
            ),
            const SizedBox(height: 20),
            _DetailLine(label: 'Year', value: '${publication.year}'),
            _DetailLine(label: 'Type', value: publication.workType),
            _DetailLine(label: 'Journal', value: publication.journal),
            if (publication.hasDoi) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 72,
                    child: Text(
                      'DOI',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          publication.displayDoi,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextButton.icon(
                          onPressed: () => _copyDoi(publication),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy DOI'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Authors',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...visibleAuthors.map(
              (author) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: author.hasOpenAlexId
                      ? () => _openAuthor(author)
                      : null,
                  child: Row(
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          author.name,
                          style: TextStyle(
                            decoration: author.hasOpenAlexId
                                ? TextDecoration.underline
                                : null,
                            color: author.hasOpenAlexId
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (author.hasOpenAlexId)
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasManyAuthors)
              TextButton(
                onPressed: () {
                  setState(() => _expandedAuthors = !_expandedAuthors);
                },
                child: Text(
                  _expandedAuthors
                      ? 'Show less'
                      : 'Show all ${authors.length} authors',
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Abstract',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              publication.abstractText,
              maxLines: _expandedAbstract ? null : 8,
              overflow: _expandedAbstract ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: 14,
              ),
            ),
            if (publication.abstractText.length > 180)
              TextButton(
                onPressed: () {
                  setState(() => _expandedAbstract = !_expandedAbstract);
                },
                child: Text(_expandedAbstract ? 'Show less' : 'Show more'),
              ),
            if (publication.relatedWorkIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Related Papers',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              if (_loadingRelated)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_relatedWorks.isEmpty)
                const Text(
                  'No related papers loaded from OpenAlex.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                ..._relatedWorks.map(
                  (paper) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        paper.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${paper.year} · '
                        '${formatOpenAlexCount(paper.citations)} citations',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(publication: paper),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinksSection extends StatelessWidget {
  final Publication publication;
  final Future<void> Function(String url) onOpenUrl;

  const _LinksSection({
    required this.publication,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final links = <({String label, String url, IconData icon})>[];

    if (publication.openAlexUrl.isNotEmpty) {
      links.add((
        label: 'View on OpenAlex',
        url: publication.openAlexUrl,
        icon: Icons.language_outlined,
      ));
    }

    if (publication.doiUrl != null) {
      links.add((
        label: 'Open DOI',
        url: publication.doiUrl!,
        icon: Icons.link,
      ));
    }

    if (publication.landingPageUrl != null &&
        publication.landingPageUrl != publication.readUrl) {
      links.add((
        label: 'Publisher page',
        url: publication.landingPageUrl!,
        icon: Icons.article_outlined,
      ));
    }

    if (links.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Links',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: links
              .map(
                (link) => OutlinedButton.icon(
                  onPressed: () => onOpenUrl(link.url),
                  icon: Icon(link.icon, size: 16),
                  label: Text(link.label),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
