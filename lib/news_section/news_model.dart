import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String? id;
  final String title;
  final String description;
  final String image;
  final String type; // Event, Admission, Notice
  final String date;
  final DateTime? expiryDate;
  final dynamic createdAt;

  NewsModel({
    this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.type,
    required this.date,
    this.expiryDate,
    this.createdAt,
  });

  factory NewsModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return NewsModel(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      image: data['image'] as String? ?? '',
      type: data['type'] as String? ?? 'General',
      date: data['date'] as String? ?? '',
      expiryDate: data['expiryDate'] is Timestamp
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'],
    );
  }

  factory NewsModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NewsModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'image': image,
      'type': type,
      'date': date,
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
