import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/models/support_models.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/data/repositories.dart';
import '../../../shared/widgets/common_widgets.dart';

final latestConversationMessageProvider =
    StreamProvider.family<MessageModel?, String>((ref, conversationId) {
      return ref
          .read(chatRepositoryProvider)
          .watchLatestMessage(conversationId);
    });

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authRepositoryProvider).currentUser;
    if (authUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view messages')),
      );
    }

    final profileAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          final isHospital = profile?.role == AppConstants.roleHospital;
          final appointmentsAsync = isHospital
              ? ref.watch(hospitalAppointmentsProvider(authUser.uid))
              : ref.watch(patientAppointmentsProvider(authUser.uid));

          return appointmentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (appointments) {
              if (appointments.isEmpty) {
                return EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No messages yet',
                  subtitle: isHospital
                      ? 'Patient conversations will appear after bookings are created.'
                      : 'Your hospital conversations will appear after booking.',
                );
              }

              final sortedAppointments = [...appointments]
                ..sort((a, b) {
                  final aDate = a.updatedAt ?? a.createdAt ?? a.appointmentDate;
                  final bDate = b.updatedAt ?? b.createdAt ?? b.appointmentDate;
                  return bDate.compareTo(aDate);
                });

              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: sortedAppointments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final appointment = sortedAppointments[i];
                  return _ConversationTile(
                    appointment: appointment,
                    title: isHospital
                        ? (appointment.patientName ?? 'Patient')
                        : (appointment.hospitalName ?? 'Hospital'),
                    subtitleFallback:
                        '${appointment.departmentName ?? appointment.serviceName ?? 'Appointment'} · ${DateFormat('MMM d, h:mm a').format(appointment.appointmentDate)}',
                    icon: isHospital
                        ? Icons.person_outline_rounded
                        : Icons.local_hospital,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({
    required this.appointment,
    required this.title,
    required this.subtitleFallback,
    required this.icon,
  });

  final AppointmentModel appointment;
  final String title;
  final String subtitleFallback;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestMessageAsync = ref.watch(
      latestConversationMessageProvider(appointment.id),
    );

    return latestMessageAsync.when(
      loading: () => _ConversationListTile(
        title: title,
        subtitle: subtitleFallback,
        trailing: DateFormat('MMM d').format(appointment.appointmentDate),
        icon: icon,
        onTap: () => context.push(
          '/chat/${appointment.id}?title=${Uri.encodeComponent(title)}',
        ),
      ),
      error: (_, _) => _ConversationListTile(
        title: title,
        subtitle: subtitleFallback,
        trailing: DateFormat('MMM d').format(appointment.appointmentDate),
        icon: icon,
        onTap: () => context.push(
          '/chat/${appointment.id}?title=${Uri.encodeComponent(title)}',
        ),
      ),
      data: (latestMessage) {
        final subtitle = latestMessage?.text.isNotEmpty == true
            ? latestMessage!.text
            : subtitleFallback;
        final trailingDate =
            latestMessage?.createdAt ??
            appointment.updatedAt ??
            appointment.createdAt ??
            appointment.appointmentDate;

        return _ConversationListTile(
          title: title,
          subtitle: subtitle,
          trailing: _formatTrailingTime(trailingDate),
          icon: icon,
          onTap: () => context.push(
            '/chat/${appointment.id}?title=${Uri.encodeComponent(title)}',
          ),
        );
      },
    );
  }

  static String _formatTrailingTime(DateTime value) {
    final now = DateTime.now();
    final isSameDay =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    return isSameDay
        ? DateFormat('h:mm a').format(value)
        : DateFormat('MMM d').format(value);
  }
}

class _ConversationListTile extends StatelessWidget {
  const _ConversationListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: CircleAvatar(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.15),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(trailing, style: Theme.of(context).textTheme.bodySmall),
      onTap: onTap,
    );
  }
}
