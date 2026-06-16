import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DepartmentModel extends Equatable {
  const DepartmentModel({
    required this.id,
    required this.hospitalId,
    required this.name,
    this.doctorName,
    this.specialty,
    this.description,
    this.consultationFee = 0,
    this.isActive = true,
    this.imageUrl,
  });

  final String id;
  final String hospitalId;
  final String name;
  final String? doctorName;
  final String? specialty;
  final String? description;
  final double consultationFee;
  final bool isActive;
  final String? imageUrl;

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DepartmentModel.fromMap(data, id: doc.id);
  }

  factory DepartmentModel.fromMap(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return DepartmentModel(
      id: id,
      hospitalId: data['hospitalId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? data['doctor'] as String?,
      specialty: data['specialty'] as String?,
      description: data['description'] as String?,
      consultationFee: (data['consultationFee'] as num?)?.toDouble() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'hospitalId': hospitalId,
    'name': name,
    'doctorName': doctorName,
    'specialty': specialty,
    'description': description,
    'consultationFee': consultationFee,
    'isActive': isActive,
    'imageUrl': imageUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [id, hospitalId, name];
}

class ServiceModel extends Equatable {
  const ServiceModel({
    required this.id,
    required this.hospitalId,
    required this.name,
    this.departmentId,
    this.description,
    this.price = 0,
    this.durationMinutes = 30,
    this.isActive = true,
    this.category,
  });

  final String id;
  final String hospitalId;
  final String name;
  final String? departmentId;
  final String? description;
  final double price;
  final int durationMinutes;
  final bool isActive;
  final String? category;

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ServiceModel.fromMap(data, id: doc.id);
  }

  factory ServiceModel.fromMap(
    Map<String, dynamic> data, {
    required String id,
  }) {
    return ServiceModel(
      id: id,
      hospitalId: data['hospitalId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      departmentId: data['departmentId'] as String?,
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: data['durationMinutes'] as int? ?? 30,
      isActive: data['isActive'] as bool? ?? true,
      category: data['category'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'hospitalId': hospitalId,
    'name': name,
    'departmentId': departmentId,
    'description': description,
    'price': price,
    'durationMinutes': durationMinutes,
    'isActive': isActive,
    'category': category,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  List<Object?> get props => [id, hospitalId, name, isActive];
}
