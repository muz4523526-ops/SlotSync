import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/data/repositories.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    final appointmentsAsync = ref.watch(hospitalAppointmentsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appointments) {
          final today = DateTime.now();
          final todayAppts = appointments.where((a) {
            final d = a.appointmentDate;
            return d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          }).toList();
          final confirmed = appointments
              .where((a) => a.status == AppConstants.statusConfirmed)
              .length;
          final revenue = appointments
              .where((a) => a.status == AppConstants.statusCompleted)
              .fold<double>(0, (sum, a) => sum + a.consultationFee);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Today',
                      value: '${todayAppts.length}',
                      subtitle: 'Appointments',
                      icon: Icons.event,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Confirmed',
                      value: '$confirmed',
                      subtitle: 'Active',
                      icon: Icons.check_circle,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Patients',
                      value:
                          '${appointments.map((a) => a.patientId).toSet().length}',
                      subtitle: 'Total',
                      icon: Icons.people,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Revenue',
                      value: '₹${revenue.toStringAsFixed(0)}',
                      subtitle: 'Completed',
                      icon: Icons.payments,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Utilization',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: appointments.isEmpty
                          ? 0
                          : confirmed / appointments.length,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appointments.isEmpty
                          ? 'No data yet'
                          : '${((confirmed / appointments.length) * 100).toStringAsFixed(0)}% slot utilization',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
