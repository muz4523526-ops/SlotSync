import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/data/repositories.dart';
import '../../hospitals/presentation/hospital_detail_screen.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    final hospitalAsync = ref.watch(hospitalDetailProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Profile')),
      body: hospitalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (hospital) {
          if (hospital != null) {
            _nameController.text = hospital.name;
            _addressController.text = hospital.address ?? '';
            _phoneController.text = hospital.phone ?? '';
            _descriptionController.text = hospital.description ?? '';
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        hospital?.isVerified == true
                            ? Icons.verified
                            : Icons.pending,
                        color: hospital?.isVerified == true
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      title: Text(
                        hospital?.isVerified == true
                            ? 'Verified Hospital'
                            : 'Verification Pending',
                      ),
                      subtitle: const Text('Upload documents to get verified'),
                      trailing: const Icon(Icons.upload_file),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Verification document uploads are not connected yet.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: Icon(
                    ref.watch(themeModeProvider) == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  value: ref.watch(themeModeProvider) == ThemeMode.dark,
                  onChanged: (_) =>
                      ref.read(themeModeProvider.notifier).toggle(),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Hospital Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Save Profile',
                onPressed: () async {
                  await ref
                      .read(hospitalRepositoryProvider)
                      .updateHospitalProfile(user.uid, {
                        'name': _nameController.text,
                        'address': _addressController.text,
                        'phone': _phoneController.text,
                        'description': _descriptionController.text,
                      });
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved')),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/auth/login');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }
}
