import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';

import '../services/analytics_service.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../services/remote_config_service.dart';
import '../services/crashlytics_service.dart';
import '../services/messaging_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/publication_viewmodel.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';

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
  bool _fcmExpanded = false;
  bool _isRefreshingConfig = false;
  int _configRevision = 0;
  String? _localPdfPath;

  @override
  void initState() {
    super.initState();
    MessagingService.refreshToken();
  }

  Future<void> _exportPdfAndUpload() async {
    final messenger = ScaffoldMessenger.of(context);
    final publicationProvider = context.read<PublicationViewModel>();

    setState(() {
      _isUploading = true;
      _localPdfPath = null;
    });

    try {
      final file = await PdfService.generateReport(
        topic: publicationProvider.currentTopic,
        papers: publicationProvider.publications,
        journals: publicationProvider.topJournalsOpenAlex,
        authors: publicationProvider.topAuthorsOpenAlex,
      );

      await AnalyticsService.logExportPdf(
        publicationProvider.currentTopic,
      );

      setState(() => _localPdfPath = file.path);

      final url = await StorageService.uploadPdf(file);

      if (!mounted) return;
      setState(() {
        _uploadedUrl = url;
        _isUploading = false;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('PDF exported and uploaded successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      final hasLocal = _localPdfPath != null;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hasLocal
                ? 'PDF đã tạo local. Upload cloud lỗi: $e'
                : 'Export failed: $e',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _refreshRemoteConfig() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isRefreshingConfig = true);
    final ok = await RemoteConfigService.refresh();
    if (!mounted) return;
    setState(() {
      _isRefreshingConfig = false;
      _configRevision++;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Remote Config refreshed'
              : 'Remote Config refresh failed (dùng giá trị mặc định)',
        ),
      ),
    );
  }

  Future<void> _copyFcmToken() async {
    final messenger = ScaffoldMessenger.of(context);
    final token = await MessagingService.refreshToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('FCM token chưa sẵn sàng')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Đã copy FCM token — dán vào Firebase Console test')),
    );
  }

  Future<void> _previewPdf() async {
    final messenger = ScaffoldMessenger.of(context);
    final publicationProvider = context.read<PublicationViewModel>();

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
    messenger.showSnackBar(
      const SnackBar(content: Text('PDF preview completed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final _ = _configRevision;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(auth),
          const SizedBox(height: 24),
          _buildAccountSection(auth),
          const SizedBox(height: 24),
          _buildFcmSection(),
          const SizedBox(height: 24),
          _buildNotificationSection(),
          const SizedBox(height: 24),
          _buildRemoteConfigSection(),
          const SizedBox(height: 24),
          _buildCrashlyticsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthViewModel auth) {
    final user = auth.currentUser;
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user?.photoUrl != null
              ? NetworkImage(user!.photoUrl!)
              : null,
          child: user?.photoUrl == null
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
      ],
    );
  }

  Widget _buildAccountSection(AuthViewModel auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                key: const Key('export_pdf_button'),
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
              if (_localPdfPath != null) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Local PDF'),
                  subtitle: Text(
                    _localPdfPath!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => OpenFilex.open(_localPdfPath!),
                ),
              ],
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
                leading: const Icon(Icons.info_outline),
                title: const Text('About JournalAI'),
                subtitle: const Text('App info · OpenAlex API key'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        body: AboutScreen(),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () async {
                  await auth.signOut();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFcmSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Firebase Cloud Messaging',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<int>(
          valueListenable: MessagingService.revision,
          builder: (context, revision, child) {
            final token = MessagingService.token;
            return Card(
              child: Column(
                children: [
                  ListTile(
                    key: const Key('fcm_token_section'),
                    leading: const Icon(Icons.token),
                    title: const Text('FCM Device Token'),
                    subtitle: Text(
                      token == null
                          ? 'Chưa có token — cần quyền notification'
                          : '${token.substring(0, token.length.clamp(0, 24))}…',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Icon(
                      _fcmExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onTap: () {
                      setState(() => _fcmExpanded = !_fcmExpanded);
                    },
                  ),
                  if (_fcmExpanded && token != null) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        token,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.copy),
                      title: const Text('Copy token'),
                      subtitle: const Text(
                        'Dán vào Firebase Console → Messaging → Send test',
                      ),
                      onTap: _copyFcmToken,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Center',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<int>(
          valueListenable: MessagingService.revision,
          builder: (context, revision, child) {
            final messages = MessagingService.messages;
            return Card(
              child: messages.isEmpty
                  ? const ListTile(
                      leading: Icon(Icons.notifications_none),
                      title: Text('No notifications'),
                      subtitle: Text(
                        'Push notifications from Firebase will appear here',
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < messages.length && i < 10; i++)
                          ListTile(
                            leading: const Icon(
                              Icons.notification_important,
                              size: 20,
                            ),
                            title: Text(
                              messages[i].notification?.title ??
                                  'Notification',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildRemoteConfigSection() {
    final maxJournals = RemoteConfigService.maxJournals;
    final maxKeywords = RemoteConfigService.maxKeywords;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                key: const Key('remote_config_section'),
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
                        value: '$maxJournals',
                      ),
                      const SizedBox(height: 8),
                      _ConfigValueTile(
                        label: 'Max Keywords Displayed',
                        value: '$maxKeywords',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('refresh_remote_config'),
                        onPressed:
                            _isRefreshingConfig ? null : _refreshRemoteConfig,
                        icon: _isRefreshingConfig
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh from Firebase'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Values from Firebase Remote Config (defaults if fetch fails).',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCrashlyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
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
