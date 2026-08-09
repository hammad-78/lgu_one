import 'package:flutter/material.dart';
import 'news_model.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsModel news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.type),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(news.image),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    news.date,
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    news.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}