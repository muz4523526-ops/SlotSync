import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../theme/app_colors.dart';
import '../../hospitals/data/repositories.dart';

final hospitalDetailProvider = FutureProvider.family((ref, String id) async {
  return ref.read(hospitalRepositoryProvider).getHospital(id);
});

final hospitalDepartmentsProvider = StreamProvider.family((
  ref,
  String hospitalId,
) {
  return ref.read(hospitalRepositoryProvider).watchDepartments(hospitalId);
});

final hospitalServicesProvider = StreamProvider.family((
  ref,
  String hospitalId,
) {
  return ref.read(hospitalRepositoryProvider).watchServices(hospitalId);
});

final hospitalReviewsProvider = StreamProvider.family((ref, String hospitalId) {
  return ref.read(hospitalRepositoryProvider).watchReviews(hospitalId);
});

class HospitalDetailScreen extends ConsumerWidget {
  const HospitalDetailScreen({super.key, required this.hospitalId});

  final String hospitalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hospitalAsync = ref.watch(hospitalDetailProvider(hospitalId));
    final departmentsAsync = ref.watch(hospitalDepartmentsProvider(hospitalId));
    final servicesAsync = ref.watch(hospitalServicesProvider(hospitalId));
    final reviewsAsync = ref.watch(hospitalReviewsProvider(hospitalId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: hospitalAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (hospital) {
            if (hospital == null) {
              return const Center(child: Text('Hospital not found'));
            }
            return NestedScrollView(
              headerSliverBuilder: (_, _) => [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_hospital_rounded,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    title: Text(
                      hospital.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (hospital.isVerified) ...[
                              Icon(
                                Icons.verified,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Icon(
                              Icons.star_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            Text(
                              ' ${hospital.rating.toStringAsFixed(1)} (${hospital.reviewCount} reviews)',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hospital.fullAddress,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (hospital.phone != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            hospital.phone!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Services'),
                        Tab(text: 'Reviews'),
                        Tab(text: 'Info'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _OverviewTab(
                    hospital: hospital,
                    description: hospital.description,
                  ),
                  servicesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (services) => _ServicesTab(
                      hospitalId: hospitalId,
                      services: services,
                      departmentsAsync: departmentsAsync,
                    ),
                  ),
                  reviewsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                    data: (reviews) => ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: reviews.length,
                      itemBuilder: (_, i) {
                        final r = reviews[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      r.patientName ?? 'Patient',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const Spacer(),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (j) => Icon(
                                            Icons.star,
                                            size: 16,
                                            color: j < r.rating
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.outlineVariant,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (r.comment != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    r.comment!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _InfoTab(hospital: hospital),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: hospitalAsync.maybeWhen(
          data: (h) => h != null
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GradientButton(
                      label: 'Book Appointment',
                      icon: Icons.calendar_today_rounded,
                      onPressed: () => context.push('/book/$hospitalId'),
                    ),
                  ),
                )
              : null,
          orElse: () => null,
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.hospital, this.description});

  final dynamic hospital;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                description ?? 'No description available.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (hospital.specialties.isNotEmpty) ...[
          Text('Specialties', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (hospital.specialties as List<String>)
                .map(
                  (s) => Chip(
                    label: Text(s),
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ServicesTab extends StatelessWidget {
  const _ServicesTab({
    required this.hospitalId,
    required this.services,
    required this.departmentsAsync,
  });

  final String hospitalId;
  final List services;
  final AsyncValue departmentsAsync;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return departmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (departments) {
          if (departments.isEmpty) {
            return const EmptyState(
              icon: Icons.medical_services_outlined,
              title: 'No services yet',
              subtitle: 'This hospital hasn\'t listed services.',
            );
          }
          return ListView.builder(
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
                            if (d.doctorName != null)
                              Text(
                                'Dr. ${d.doctorName}',
                                style: Theme.of(context).textTheme.bodySmall,
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
                      ElevatedButton(
                        onPressed: () => context.push(
                          '/book/$hospitalId?departmentId=${d.id}',
                        ),
                        child: const Text('Book'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: services.length,
      itemBuilder: (_, i) {
        final s = services[i];
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
                        s.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${s.durationMinutes} min · ₹${s.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      context.push('/book/$hospitalId?serviceId=${s.id}'),
                  child: const Text('Book'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.hospital});

  final dynamic hospital;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: hospital.fullAddress,
              ),
              const Divider(),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: hospital.phone ?? 'N/A',
              ),
              const Divider(),
              _InfoRow(
                icon: Icons.language_outlined,
                label: 'Website',
                value: hospital.website ?? 'N/A',
              ),
            ],
          ),
        ),
        if (hospital.latitude != null && hospital.longitude != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(
                  'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
                );
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.directions_outlined),
              label: const Text('Get Directions'),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(child: tabBar);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
