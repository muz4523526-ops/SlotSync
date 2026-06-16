import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/appointment_model.dart'
    show AppointmentModel, SlotModel;
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/data/repositories.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({
    super.key,
    required this.hospitalId,
    this.serviceId,
    this.departmentId,
  });

  final String hospitalId;
  final String? serviceId;
  final String? departmentId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  SlotModel? _selectedSlot;
  final _notesController = TextEditingController();
  bool _isLoading = false;
  List<SlotModel> _slots = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);
    try {
      final slots = await ref
          .read(appointmentRepositoryProvider)
          .getAvailableSlots(
            hospitalId: widget.hospitalId,
            date: _selectedDate,
            departmentId: widget.departmentId,
          );
      if (mounted) setState(() => _slots = slots);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load slots: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _slots = []);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmBooking() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || _selectedSlot == null) return;

    setState(() => _isLoading = true);
    try {
      final hospitalRepository = ref.read(hospitalRepositoryProvider);
      final hospital = await hospitalRepository.getHospital(widget.hospitalId);
      final serviceId = widget.serviceId ?? _selectedSlot?.serviceId;
      final departmentId = widget.departmentId ?? _selectedSlot?.departmentId;
      final service = serviceId != null
          ? await hospitalRepository.getService(serviceId)
          : null;
      final department = departmentId != null
          ? await hospitalRepository.getDepartment(departmentId)
          : service?.departmentId != null
          ? await hospitalRepository.getDepartment(service!.departmentId!)
          : null;
      final appointmentDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(_selectedSlot!.startTime.split(':')[0]),
        int.parse(_selectedSlot!.startTime.split(':')[1]),
      );

      final appointment = AppointmentModel(
        id: '',
        patientId: user.uid,
        hospitalId: widget.hospitalId,
        appointmentDate: appointmentDate,
        patientName: user.displayName,
        hospitalName: hospital?.name,
        departmentId: departmentId,
        departmentName: department?.name,
        serviceId: serviceId,
        serviceName: service?.name,
        doctorName: department?.doctorName,
        slotId: _selectedSlot!.id,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        qrCode: const Uuid().v4(),
        consultationFee: service?.price ?? department?.consultationFee ?? 0,
        status: AppConstants.statusPending,
      );

      final id = await ref
          .read(appointmentRepositoryProvider)
          .bookAppointment(appointment);
      if (!mounted) return;
      context.go('/booking-success/$id');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Booking failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    } on FirestoreException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0) {
            _loadSlots();
            setState(() => _step = 1);
          } else if (_step == 1 && _selectedSlot != null) {
            setState(() => _step = 2);
          } else if (_step == 2) {
            setState(() => _step = 3);
          } else if (_step == 3) {
            _confirmBooking();
          }
        },
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_step < 3)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: const Text('Continue'),
                  )
                else
                  GradientButton(
                    label: 'Confirm Booking',
                    isLoading: _isLoading,
                    onPressed: details.onStepContinue,
                    width: 200,
                  ),
                if (details.onStepCancel != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Select Date'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              onDateChanged: (d) => setState(() => _selectedDate = d),
            ),
          ),
          Step(
            title: const Text('Select Slot'),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _slots.isEmpty
                ? const Text('No slots available for this date.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((slot) {
                      final selected = _selectedSlot?.id == slot.id;
                      return ChoiceChip(
                        label: Text('${slot.startTime} - ${slot.endTime}'),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedSlot = slot),
                      );
                    }).toList(),
                  ),
          ),
          Step(
            title: const Text('Patient Details'),
            isActive: _step >= 2,
            state: _step > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Symptoms (optional)',
                    hintText: 'Describe your symptoms or reason for visit',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Medical report uploads are not connected yet.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Medical Report'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _step >= 3,
            content: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}',
                  ),
                  if (_selectedSlot != null)
                    Text(
                      'Time: ${_selectedSlot!.startTime} - ${_selectedSlot!.endTime}',
                    ),
                  if (_notesController.text.isNotEmpty)
                    Text('Notes: ${_notesController.text}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Booking Confirmed!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your appointment has been booked successfully. You\'ll receive a confirmation shortly.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              GradientButton(
                label: 'View Appointments',
                onPressed: () => context.go('/appointments'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
