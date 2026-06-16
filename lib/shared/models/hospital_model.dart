import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class HospitalModel extends Equatable {
  const HospitalModel({
    required this.id,
    required this.name,
    required this.email,
    this.description,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.phone,
    this.website,
    this.imageUrl,
    this.coverImageUrl,
    this.latitude,
    this.longitude,
    this.rating = 0,
    this.reviewCount = 0,
    this.specialties = const [],
    this.insuranceAccepted = const [],
    this.isVerified = false,
    this.verificationStatus = 'pending',
    this.openHours,
    this.departmentIds = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? phone;
  final String? website;
  final String? imageUrl;
  final String? coverImageUrl;
  final double? latitude;
  final double? longitude;
  final double rating;
  final int reviewCount;
  final List<String> specialties;
  final List<String> insuranceAccepted;
  final bool isVerified;
  final String verificationStatus;
  final Map<String, dynamic>? openHours;
  final List<String> departmentIds;
  final DateTime? createdAt;

  String get fullAddress {
    final parts = [
      address,
      city,
      state,
      zipCode,
    ].where((e) => e != null && e.isNotEmpty);
    return parts.join(', ');
  }

  factory HospitalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HospitalModel.fromMap(data, id: doc.id);
  }

  factory HospitalModel.fromMap(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return HospitalModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      description: data['description'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      zipCode: data['zipCode'] as String?,
      phone: data['phone'] as String?,
      website: data['website'] as String?,
      imageUrl: data['imageUrl'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      specialties: List<String>.from(data['specialties'] ?? []),
      insuranceAccepted: List<String>.from(data['insuranceAccepted'] ?? []),
      isVerified: data['isVerified'] as bool? ?? false,
      verificationStatus: data['verificationStatus'] as String? ?? 'pending',
      openHours: data['openHours'] as Map<String, dynamic>?,
      departmentIds: List<String>.from(data['departmentIds'] ?? []),
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'description': description,
    'address': address,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'phone': phone,
    'website': website,
    'imageUrl': imageUrl,
    'coverImageUrl': coverImageUrl,
    'latitude': latitude,
    'longitude': longitude,
    'rating': rating,
    'reviewCount': reviewCount,
    'specialties': specialties,
    'insuranceAccepted': insuranceAccepted,
    'isVerified': isVerified,
    'verificationStatus': verificationStatus,
    'openHours': openHours,
    'departmentIds': departmentIds,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  List<Object?> get props => [id, name, rating, isVerified];
}
