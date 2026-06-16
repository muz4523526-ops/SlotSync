import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/appointment_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/data/repositories.dart';

class AdminSlotsScreen extends ConsumerStatefulWidget {
  const AdminSlotsScreen({super.key});

  @override
  ConsumerState<AdminSlotsScreen> createState() => _AdminSlotsScreenState();
}

class _AdminSlotsScreenState extends ConsumerState<AdminSlotsScreen> {
  final DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  final _startTimeController = TextEditingController(text: '09:00');
  final _endTimeController = TextEditingController(text: '09:30');
  int _capacity = 1;

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _createSlot() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    try {
      await ref
          .read(appointmentRepositoryProvider)
          .createSlot(
            SlotModel(
              id: '',
              hospitalId: user.uid,
              date: _selectedDate,
              startTime: _startTimeController.text,
              endTime: _endTimeController.text,
              capacity: _capacity,
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Slot created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating slot: $e'),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkDanger
                : AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    final slotsAsync = ref.watch(
      StreamProvider(
        (ref) => ref
            .read(appointmentRepositoryProvider)
            .watchHospitalSlots(user.uid),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Slot Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Slot',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _startTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Start (HH:mm)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _endTimeController,
                          decoration: const InputDecoration(
                            labelText: 'End (HH:mm)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Capacity:'),
                      Expanded(
                        child: Slider(
                          value: _capacity.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_capacity',
                          onChanged: (v) =>
                              setState(() => _capacity = v.toInt()),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _createSlot,
                    child: const Text('Add Slot'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: slotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (slots) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: slots.length,
                itemBuilder: (_, i) {
                  final slot = slots[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${slot.startTime} - ${slot.endTime}'),
                                Text(
                                  '${slot.date.day}/${slot.date.month}/${slot.date.year} · ${slot.bookedCount}/${slot.capacity} booked',
                                ),
                              ],
                            ),
                          ),
                          if (slot.isBlocked)
                            Chip(
                              label: Text(
                                'Blocked',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkDanger
                                      : AppColors.danger,
                                ),
                              ),
                              backgroundColor:
                                  (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkDanger
                                          : AppColors.danger)
                                      .withValues(alpha: 0.15),
                            )
                          else if (!slot.isAvailable)
                            Chip(
                              label: Text(
                                'Full',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkWarning
                                      : AppColors.warning,
                                ),
                              ),
                              backgroundColor:
                                  (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkWarning
                                          : AppColors.warning)
                                      .withValues(alpha: 0.15),
                            )
                          else
                            Chip(
                              label: Text(
                                'Available',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkSuccess
                                      : AppColors.success,
                                ),
                              ),
                              backgroundColor:
                                  (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkSuccess
                                          : AppColors.success)
                                      .withValues(alpha: 0.15),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
