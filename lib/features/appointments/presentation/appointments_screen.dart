import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/data/repositories.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final appointmentsAsync = ref.watch(patientAppointmentsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appointments) => TabBarView(
          controller: _tabController,
          children: [
            _AppointmentList(
              appointments: appointments
                  .where(
                    (a) =>
                        a.isUpcoming &&
                        a.status != AppConstants.statusCancelled,
                  )
                  .toList(),
              emptyTitle: 'No upcoming appointments',
              emptySubtitle: 'Book an appointment to get started.',
              onEmptyAction: () => context.go('/search'),
            ),
            _AppointmentList(
              appointments: appointments
                  .where(
                    (a) => a.isPast && a.status != AppConstants.statusCancelled,
                  )
                  .toList(),
              emptyTitle: 'No past appointments',
              emptySubtitle: 'Your completed visits will appear here.',
            ),
            _AppointmentList(
              appointments: appointments
                  .where((a) => a.status == AppConstants.statusCancelled)
                  .toList(),
              emptyTitle: 'No cancelled appointments',
              emptySubtitle: 'Cancelled bookings will appear here.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentList extends ConsumerWidget {
  const _AppointmentList({
    required this.appointments,
    required this.emptyTitle,
    required this.emptySubtitle,
    this.onEmptyAction,
  });

  final List<AppointmentModel> appointments;
  final String emptyTitle;
  final String emptySubtitle;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointments.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionLabel: onEmptyAction != null ? 'Find Care' : null,
        onAction: onEmptyAction,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (_, i) {
        final apt = appointments[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        apt.hospitalName ?? 'Hospital',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    StatusBadge(status: apt.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  apt.departmentName ?? apt.serviceName ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat(
                        'EEE, MMM d · h:mm a',
                      ).format(apt.appointmentDate),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(
                      '/chat/${apt.id}?title=${Uri.encodeComponent(apt.hospitalName ?? 'Hospital')}',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message Hospital'),
                  ),
                ),
                if (apt.status == AppConstants.statusPending ||
                    apt.status == AppConstants.statusConfirmed) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showQrTicket(context, apt),
                          icon: const Icon(Icons.qr_code, size: 18),
                          label: const Text('QR Ticket'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _cancelAppointment(context, ref, apt),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrTicket(BuildContext context, AppointmentModel apt) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Appointment Ticket',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              QrImageView(data: apt.qrCode ?? apt.id, size: 180),
              const SizedBox(height: 16),
              Text(
                apt.hospitalName ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                DateFormat('MMM d, yyyy · h:mm a').format(apt.appointmentDate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelAppointment(
    BuildContext context,
    WidgetRef ref,
    AppointmentModel apt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(appointmentRepositoryProvider).cancelAppointment(apt.id);
    }
  }
}
