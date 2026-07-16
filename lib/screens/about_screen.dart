<<<<<<< HEAD
// Tab About — API key (UI gốc)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/publication_provider.dart';
=======
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

>>>>>>> feature/lab3
import '../services/openalex_config.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _saving = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  Future<void> _saveKey() async {
    setState(() => _saving = true);

    try {
      final provider = context.read<PublicationProvider>();
      await provider.saveOpenAlexApiKey(_keyController.text);
      if (!mounted) return;

      _keyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenAlex API key saved')),
      );

      await provider.refreshCurrentAnalysis();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearKey() async {
    setState(() => _saving = true);

    try {
      final provider = context.read<PublicationProvider>();
      await provider.clearOpenAlexApiKey();
      _keyController.clear();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved API key removed')),
=======
  Future<void> _saveKey(OpenAlexConfig config) async {
    setState(() => _saving = true);
    try {
      await config.saveKey(_keyController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            config.hasSavedKey
                ? 'Đã lưu OpenAlex API key'
                : 'Đã xóa OpenAlex API key',
          ),
        ),
>>>>>>> feature/lab3
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<OpenAlexConfig>();
<<<<<<< HEAD
    final provider = context.watch<PublicationProvider>();
=======
>>>>>>> feature/lab3

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const JournalAiAppBar(showBell: false),
          const SizedBox(height: 24),
          const Center(child: AppLogo(size: 72)),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'JournalAI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Research Intelligence Platform',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 28),
          MockupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OpenAlex API Key',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your key here to use the app without rebuilding. '
                  'Get a free key at openalex.org/settings/api',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _keyController,
                  obscureText: _obscureKey,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    hintText: config.hasKey
                        ? 'Enter new key to replace saved key'
                        : 'Paste OpenAlex API key',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureKey = !_obscureKey);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      config.hasKey ? Icons.check_circle_outline : Icons.info_outline,
                      size: 16,
                      color: config.hasKey
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        config.hasKey
                            ? 'Active · ${config.keySourceLabel}'
                            : 'No key · some requests may be rate-limited',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _saveKey,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save key'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _saving || !config.hasSavedKey
                          ? null
                          : _clearKey,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MockupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Journal Trend Analyzer helps researchers understand global publication trends, citation impact, and emerging topics using live data from OpenAlex.',
                  style: TextStyle(
                    height: 1.5,
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
<<<<<<< HEAD
                const _AboutRow(label: 'Data Source', value: 'OpenAlex API'),
                _AboutRow(
                  label: 'Coverage',
                  value: '2000–${DateTime.now().year}',
                ),
                _AboutRow(
                  label: 'Total Records',
                  value: provider.hasData
                      ? provider.formattedTotalOnOpenAlex
                      : 'Loading from OpenAlex…',
                ),
                const _AboutRow(label: 'Version', value: '1.0.0'),
                const _AboutRow(label: 'Course', value: 'PRM393 Lab 2'),
=======
                _AboutRow(label: 'Data Source', value: 'OpenAlex API'),
                _AboutRow(
                  label: 'Coverage',
                  value: '2015–${DateTime.now().year}',
                ),
                _AboutRow(label: 'Total Records', value: '134M+ publications'),
                _AboutRow(label: 'Version', value: '1.0.0'),
                _AboutRow(label: 'Course', value: 'PRM393 Lab 3'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MockupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OpenAlex API Key',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nguồn: ${config.keySourceLabel}'
                  '${config.hasKey ? ' · đang dùng' : ' · chưa có key'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: 'Dán API key từ openalex.org/settings/api',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : () => _saveKey(config),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Lưu key'),
                      ),
                    ),
                    if (config.hasSavedKey) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                _keyController.clear();
                                _saveKey(config);
                              },
                        child: const Text('Xóa'),
                      ),
                    ],
                  ],
                ),
>>>>>>> feature/lab3
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;

  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
