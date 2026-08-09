class NewsModel {
  final String title;
  final String description;
  final String image;
  final String type; // Event, Admission, Notice
  final String date;

  NewsModel({
    required this.title,
    required this.description,
    required this.image,
    required this.type,
    required this.date,
  });
}