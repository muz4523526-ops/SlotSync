import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/department_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/presentation/hospital_detail_screen.dart';
import '../../hospitals/data/repositories.dart';

class AdminServicesScreen extends ConsumerStatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  ConsumerState<AdminServicesScreen> createState() =>
      _AdminServicesScreenState();
}

class _AdminServicesScreenState extends ConsumerState<AdminServicesScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _doctorController = TextEditingController();
  final _specialtyController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _doctorController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
              ),
              TextField(
                controller: _doctorController,
                decoration: const InputDecoration(labelText: 'Doctor Name'),
              ),
              TextField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Specialty'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addService, child: const Text('Add')),
        ],
      ),
    );
  }

  Future<void> _addService() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    await ref
        .read(hospitalRepositoryProvider)
        .addDepartment(
          DepartmentModel(
            id: '',
            hospitalId: user.uid,
            name: _nameController.text,
            doctorName: _doctorController.text,
            specialty: _specialtyController.text,
            consultationFee: double.tryParse(_priceController.text) ?? 0,
          ),
        );

    _nameController.clear();
    _doctorController.clear();
    _specialtyController.clear();
    _priceController.clear();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleDepartment(
    DepartmentModel department,
    bool isActive,
  ) async {
    await ref
        .read(hospitalRepositoryProvider)
        .updateDepartment(
          DepartmentModel(
            id: department.id,
            hospitalId: department.hospitalId,
            name: department.name,
            doctorName: department.doctorName,
            specialty: department.specialty,
            description: department.description,
            consultationFee: department.consultationFee,
            imageUrl: department.imageUrl,
            isActive: isActive,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    final departmentsAsync = ref.watch(hospitalDepartmentsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: departmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (departments) => ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: departments.length,
          itemBuilder: (_, i) {
            final d = departments[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'Dr. ${d.doctorName ?? 'N/A'} · ${d.specialty ?? ''}',
                          ),
                          Text(
                            '₹${d.consultationFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: d.isActive,
                      onChanged: (value) => _toggleDepartment(d, value),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
