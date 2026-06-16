import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  const ReviewModel({
    required this.id,
    required this.hospitalId,
    required this.patientId,
    required this.rating,
    this.patientName,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String hospitalId;
  final String patientId;
  final double rating;
  final String? patientName;
  final String? comment;
  final DateTime? createdAt;

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReviewModel(
      id: doc.id,
      hospitalId: data['hospitalId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      patientName: data['patientName'] as String?,
      comment: data['comment'] as String?,
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'hospitalId': hospitalId,
    'patientId': patientId,
    'rating': rating,
    'patientName': patientName,
    'comment': comment,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  List<Object?> get props => [id, hospitalId, rating];
}

class MessageModel extends Equatable {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.senderName,
    this.attachmentUrl,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String? senderName;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime? createdAt;

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      senderName: data['senderName'] as String?,
      attachmentUrl: data['attachmentUrl'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'senderName': senderName,
    'attachmentUrl': attachmentUrl,
    'isRead': isRead,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, text];
}

class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type,
    this.data,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: data['type'] as String?,
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'body': body,
    'type': type,
    'data': data,
    'isRead': isRead,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  List<Object?> get props => [id, userId, title, isRead];
}

class WaitlistModel extends Equatable {
  const WaitlistModel({
    required this.id,
    required this.patientId,
    required this.hospitalId,
    required this.serviceId,
    this.preferredDate,
    this.status = 'waiting',
    this.createdAt,
  });

  final String id;
  final String patientId;
  final String hospitalId;
  final String serviceId;
  final DateTime? preferredDate;
  final String status;
  final DateTime? createdAt;

  factory WaitlistModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WaitlistModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      hospitalId: data['hospitalId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      preferredDate: _toDateTime(data['preferredDate']),
      status: data['status'] as String? ?? 'waiting',
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'patientId': patientId,
    'hospitalId': hospitalId,
    'serviceId': serviceId,
    'preferredDate': preferredDate != null
        ? Timestamp.fromDate(preferredDate!)
        : null,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  List<Object?> get props => [id, patientId, hospitalId, status];
}

class DocumentModel extends Equatable {
  const DocumentModel({
    required this.id,
    required this.userId,
    required this.url,
    required this.fileName,
    this.type,
    this.appointmentId,
    this.uploadedAt,
  });

  final String id;
  final String userId;
  final String url;
  final String fileName;
  final String? type;
  final String? appointmentId;
  final DateTime? uploadedAt;

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DocumentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      url: data['url'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      type: data['type'] as String?,
      appointmentId: data['appointmentId'] as String?,
      uploadedAt: _toDateTime(data['uploadedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'url': url,
    'fileName': fileName,
    'type': type,
    'appointmentId': appointmentId,
    'uploadedAt': FieldValue.serverTimestamp(),
  };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  List<Object?> get props => [id, userId, fileName];
}
