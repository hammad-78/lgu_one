import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String? id;
  final String image;
  final String title;
  final String description;
  final String link;
  final DateTime? expiryDate;
  final dynamic createdAt;

  Job({
    this.id,
    required this.image,
    required this.title,
    required this.description,
    required this.link,
    this.expiryDate,
    this.createdAt,
  });

  factory Job.fromMap(Map<String, dynamic> data, [String? id]) {
    return Job(
      id: id,
      image: data['image'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      link: data['link'] as String? ?? '',
      expiryDate: data['expiryDate'] is Timestamp
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'],
    );
  }

  factory Job.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Job.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'title': title,
      'description': description,
      'link': link,
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
