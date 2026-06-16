import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  'Journal Trend Analyzer helps researchers understand global publication trends, citation impact, and emerging topics using live data from OpenAlex.',
                  style: TextStyle(
                    height: 1.5,
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _AboutRow(label: 'Data Source', value: 'OpenAlex API'),
                _AboutRow(label: 'Coverage', value: '2015–${DateTime.now().year}'),
                _AboutRow(label: 'Total Records', value: '134M+ publications'),
                _AboutRow(label: 'Version', value: '1.0.0'),
                _AboutRow(label: 'Course', value: 'PRM393 Lab 2'),
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
