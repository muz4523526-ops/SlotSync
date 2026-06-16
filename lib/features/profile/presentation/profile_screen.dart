import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../hospitals/data/repositories.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    if (mounted) context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (UserModel? user) {
          if (user == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text('Sign In'),
              ),
            );
          }

          _nameController.text = user.name;
          _phoneController.text = user.phone ?? '';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                border: InputBorder.none,
                              ),
                            ),
                            const Divider(),
                            TextField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                border: InputBorder.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Medical History',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: user.medicalHistory.isEmpty
                            ? Text(
                                'No medical history recorded.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: user.medicalHistory
                                    .map((h) => Text('• $h'))
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Dark Mode'),
                              secondary: Icon(
                                ref.watch(themeModeProvider) == ThemeMode.dark
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                              ),
                              value:
                                  ref.watch(themeModeProvider) ==
                                  ThemeMode.dark,
                              onChanged: (_) =>
                                  ref.read(themeModeProvider.notifier).toggle(),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            SwitchListTile(
                              title: const Text('Push Notifications'),
                              value: _notificationsEnabled,
                              onChanged: (v) =>
                                  setState(() => _notificationsEnabled = v),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: const Text('Documents'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Document uploads are not connected yet.',
                                    ),
                                  ),
                                );
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.help_outline),
                              title: const Text('Help & Support'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Help and support is not wired yet.',
                                    ),
                                  ),
                                );
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: 'Save Changes',
                        onPressed: () async {
                          await ref
                              .read(userRepositoryProvider)
                              .updateProfile(user.id, {
                                'name': _nameController.text,
                                'phone': _phoneController.text,
                              });
                          ref.invalidate(currentUserProvider);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated')),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: const Text('Logout'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
