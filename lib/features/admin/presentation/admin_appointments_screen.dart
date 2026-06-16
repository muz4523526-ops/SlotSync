import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/data/repositories.dart';

class AdminAppointmentsScreen extends ConsumerWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    final appointmentsAsync = ref.watch(hospitalAppointmentsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (appointments) {
          if (appointments.isEmpty) {
            return const EmptyState(
              icon: Icons.event_note,
              title: 'No appointments',
              subtitle: 'Patient bookings will appear here.',
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
                              apt.patientName ?? 'Patient',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          StatusBadge(status: apt.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${apt.departmentName ?? apt.serviceName ?? ''} · Dr. ${apt.doctorName ?? 'N/A'}',
                      ),
                      Text(
                        DateFormat(
                          'EEE, MMM d · h:mm a',
                        ).format(apt.appointmentDate),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => context.push(
                            '/chat/${apt.id}?title=${Uri.encodeComponent(apt.patientName ?? 'Patient')}',
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Chat with Patient'),
                        ),
                      ),
                      if (apt.status == AppConstants.statusPending) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(
                                  ref,
                                  apt.id,
                                  AppConstants.statusConfirmed,
                                ),
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _cancelAppointment(ref, apt.id),
                                child: const Text('Reject'),
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
        },
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, String id, String status) async {
    await ref.read(appointmentRepositoryProvider).updateStatus(id, status);
  }

  Future<void> _cancelAppointment(WidgetRef ref, String id) async {
    await ref.read(appointmentRepositoryProvider).cancelAppointment(id);
  }
}
