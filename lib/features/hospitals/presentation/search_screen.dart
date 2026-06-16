import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../shared/models/hospital_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../hospitals/data/repositories.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final searchFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final searchResultsProvider = FutureProvider<List<HospitalModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filters = ref.watch(searchFiltersProvider);
  return ref
      .read(hospitalRepositoryProvider)
      .searchHospitals(
        query: query.isEmpty ? null : query,
        specialty: filters['specialty'] as String?,
        minRating: filters['minRating'] as double?,
        insurance: filters['insurance'] as String?,
      );
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isMapView = false;
  bool _isListening = false;

  final _mapController = Completer<GoogleMapController>();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  bool _mapLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final granted = await Geolocator.requestPermission();
        if (granted == LocationPermission.denied) {
          if (mounted) setState(() => _mapLoading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _mapLoading = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          _mapLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _mapLoading = false);
    }
  }

  void _updateMarkers(List<HospitalModel> hospitals) {
    final markers = <Marker>[];
    for (final h in hospitals) {
      if (h.latitude != null && h.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId(h.id),
            position: LatLng(h.latitude!, h.longitude!),
            infoWindow: InfoWindow(title: h.name, snippet: h.fullAddress),
            onTap: () => context.push('/hospital/${h.id}'),
          ),
        );
      }
    }
    setState(() => _markers = markers.toSet());
  }

  Widget _buildMapView() {
    if (_mapLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_markers.isEmpty) {
      return const Center(child: Text('No hospitals with location data'));
    }
    final center = _currentPosition ?? _markers.first.position;
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: 12),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      onMapCreated: (controller) {
        _mapController.complete(controller);
        _fitMarkers(controller);
      },
    );
  }

  Future<void> _fitMarkers(GoogleMapController controller) async {
    if (_markers.isEmpty) return;
    final bounds = _markers
        .map((m) => m.position)
        .fold<LatLngBounds>(
          LatLngBounds(
            southwest: _markers.first.position,
            northeast: _markers.first.position,
          ),
          (bounds, latlng) => LatLngBounds(
            southwest: LatLng(
              bounds.southwest.latitude < latlng.latitude
                  ? bounds.southwest.latitude
                  : latlng.latitude,
              bounds.southwest.longitude < latlng.longitude
                  ? bounds.southwest.longitude
                  : latlng.longitude,
            ),
            northeast: LatLng(
              bounds.northeast.latitude > latlng.latitude
                  ? bounds.northeast.latitude
                  : latlng.latitude,
              bounds.northeast.longitude > latlng.longitude
                  ? bounds.northeast.longitude
                  : latlng.longitude,
            ),
          ),
        );
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FilterSheet(
        onApply: (filters) {
          ref.read(searchFiltersProvider.notifier).state = filters;
          ref.invalidate(searchResultsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) {
                            ref.read(searchQueryProvider.notifier).state = v;
                            ref.invalidate(searchResultsProvider);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search hospitals, specialties...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                              ),
                              onPressed: () {
                                setState(() => _isListening = !_isListening);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Voice search — configure speech_to_text on device',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _showFilters,
                        icon: const Icon(Icons.tune_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('List'),
                        selected: !_isMapView,
                        onSelected: (_) => setState(() => _isMapView = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Map'),
                        selected: _isMapView,
                        onSelected: (_) => setState(() => _isMapView = true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isMapView
                  ? _buildMapView()
                  : resultsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (hospitals) {
                        _updateMarkers(hospitals);
                        if (hospitals.isEmpty) {
                          return const EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No hospitals found',
                            subtitle: 'Try adjusting your search or filters.',
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: hospitals.length,
                          itemBuilder: (_, i) {
                            final h = hospitals[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                onTap: () => context.push('/hospital/${h.id}'),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        Icons.local_hospital_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  h.name,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleSmall,
                                                ),
                                              ),
                                              if (h.isVerified)
                                                Icon(
                                                  Icons.verified,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 18,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            h.fullAddress,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                color: Theme.of(context).colorScheme.primary,
                                                size: 16,
                                              ),
                                              Text(
                                                ' ${h.rating.toStringAsFixed(1)}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                              if (h.specialties.isNotEmpty) ...[
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    h.specialties.first,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.onApply});

  final ValueChanged<Map<String, dynamic>> onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _specialty;
  double _minRating = 0;
  String? _insurance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _specialty,
            decoration: const InputDecoration(labelText: 'Specialty'),
            items: [
              'Cardiology',
              'Dermatology',
              'Pediatrics',
              'Orthopedics',
              'Neurology',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _specialty = v),
          ),
          const SizedBox(height: 16),
          Text('Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 10,
            onChanged: (v) => setState(() => _minRating = v),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'Insurance Provider'),
            onChanged: (v) => _insurance = v.isEmpty ? null : v,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              widget.onApply({
                'specialty': _specialty,
                'minRating': _minRating > 0 ? _minRating : null,
                'insurance': _insurance,
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
