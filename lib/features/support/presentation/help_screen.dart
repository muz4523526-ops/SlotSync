import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    ('How do I book an appointment?',
        'Search for a hospital or specialty, tap on a hospital, select a service, pick an available slot, and confirm your booking.'),
    ('Can I cancel or reschedule?',
        'Go to the Appointments tab, tap on the booking, and select Cancel. Cancelled appointments free up the slot for others. Rescheduling is not yet supported — please cancel and rebook.'),
    ('How does the map view work?',
        'Tap the Map chip on the search screen to see hospitals plotted on a Google Map. Green markers show hospital locations. Tap a marker to jump to the hospital detail.'),
    ('Is my data secure?',
        'Yes. Authentication is handled by Firebase Auth (Google Sign-In). All data is stored in Cloud Firestore with security rules that restrict access to your own data.'),
    ('How do I contact a hospital?',
        'Open the hospital detail page and use the phone or website link. If the hospital has chat enabled, you can message them directly from the Messages tab.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Frequently Asked Questions',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ..._faqs.map((faq) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(faq.$1, style: theme.textTheme.bodyLarge),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  children: [
                    Text(faq.$2, style: theme.textTheme.bodyMedium),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          Text('Contact Us', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'support@slotsync.com',
            onTap: () async {
              final uri = Uri(
                scheme: 'mailto',
                path: 'support@slotsync.com',
                queryParameters: {
                  'subject': 'SlotSync Support Request',
                },
              );
              await launchUrl(uri);
            },
          ),
          const SizedBox(height: 8),
          _ContactCard(
            icon: Icons.chat_outlined,
            label: 'In-App Chat',
            value: 'Message us from the Messages tab',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'SlotSync v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
