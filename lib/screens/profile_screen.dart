import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../services/analytics_service.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../services/remote_config_service.dart';
import '../services/crashlytics_service.dart';
import '../services/messaging_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _uploadedUrl;
  bool _isUploading = false;
  bool _remoteConfigExpanded = false;
  bool _crashlyticsExpanded = false;

  Future<void> _exportPdfAndUpload() async {
    try {
      final publicationProvider =
          context.read<PublicationViewModel>();

      setState(() => _isUploading = true);

      final file = await PdfService.generateReport(
        topic: publicationProvider.currentTopic,
        papers: publicationProvider.publications,
        journals: publicationProvider.topJournalsOpenAlex,
        authors: publicationProvider.topAuthorsOpenAlex,
      );

      await AnalyticsService.logExportPdf(
        publicationProvider.currentTopic,
      );

      final url = await StorageService.uploadPdf(file);

      if (!mounted) return;
      setState(() {
        _uploadedUrl = url;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF exported and uploaded successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _previewPdf() async {
    try {
      final publicationProvider =
          context.read<PublicationViewModel>();

      final pdfBytes = await PdfService.generateReportBytes(
        topic: publicationProvider.currentTopic,
        papers: publicationProvider.publications,
        journals: publicationProvider.topJournalsOpenAlex,
        authors: publicationProvider.topAuthorsOpenAlex,
        totalPublications: publicationProvider.totalOnOpenAlex,
      );

      await AnalyticsService.logExportPdf(
        publicationProvider.currentTopic,
      );

      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF preview completed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preview failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.currentUser;
    final messages = MessagingService.messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user?.displayName ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              user?.email ?? 'No Email',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Account',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Export & Upload Report'),
                  subtitle: _isUploading
                      ? const Text('Uploading...')
                      : _uploadedUrl != null
                          ? const Text('Uploaded', style: TextStyle(color: Colors.green, fontSize: 12))
                          : const Text('Generate PDF and upload to Firebase'),
                  trailing: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _isUploading ? null : _exportPdfAndUpload,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.preview),
                  title: const Text('Preview Report'),
                  subtitle: const Text('View PDF before uploading'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _previewPdf,
                ),
                if (_uploadedUrl != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Uploaded Report URL'),
                    subtitle: Text(
                      _uploadedUrl!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    isThreeLine: true,
                  ),
                ],
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Notification Center',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: messages.isEmpty
                ? const ListTile(
                    leading: Icon(Icons.notifications_none),
                    title: Text('No notifications'),
                    subtitle: Text('Push notifications from Firebase will appear here'),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < messages.length && i < 10; i++)
                        ListTile(
                          leading: const Icon(Icons.notification_important, size: 20),
                          title: Text(
                            messages[i].notification?.title ?? 'Notification',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          subtitle: Text(
                            messages[i].notification?.body ?? '',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Remote Config',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_remote),
                  title: const Text('Firebase Remote Config'),
                  subtitle: const Text('Dynamic configuration values'),
                  trailing: Icon(
                    _remoteConfigExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() {
                      _remoteConfigExpanded = !_remoteConfigExpanded;
                    });
                  },
                ),
                if (_remoteConfigExpanded) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ConfigValueTile(
                          label: 'Max Journals Displayed',
                          value: '${RemoteConfigService.maxJournals}',
                        ),
                        const SizedBox(height: 8),
                        _ConfigValueTile(
                          label: 'Max Keywords Displayed',
                          value: '${RemoteConfigService.maxKeywords}',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Crashlytics',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('Firebase Crashlytics'),
                  subtitle: const Text('Crash monitoring and reporting'),
                  trailing: Icon(
                    _crashlyticsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() {
                      _crashlyticsExpanded = !_crashlyticsExpanded;
                    });
                  },
                ),
                if (_crashlyticsExpanded) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.warning_amber, color: Colors.orange),
                    title: const Text('Generate Handled Exception'),
                    subtitle: const Text('Record a non-fatal error'),
                    onTap: () async {
                      await CrashlyticsService.generateHandledException();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Handled exception recorded'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.error, color: Colors.red),
                    title: const Text('Generate Test Crash'),
                    subtitle: const Text('Trigger a fatal crash for testing'),
                    onTap: () async {
                      CrashlyticsService.generateTestCrash();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ConfigValueTile extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigValueTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
