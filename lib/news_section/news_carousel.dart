import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'news_model.dart';
import 'news_data.dart';
import 'news_detail_screen.dart';

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({super.key});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // 🔥 CAROUSEL
        CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            enlargeCenterPage: true,
            viewportFraction: 0.9,

            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),

          items: newsList.map((news) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewsDetailScreen(news: news),
                  ),
                );
              },

              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [

                    // 🔹 IMAGE (keep clean & visible)
                    Positioned.fill(
                      child: Image.network(
                        news.image,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // 🔹 EDGE DARKNESS (vignette only)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // 🔹 TOP ROW (Type + Date)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          // Type
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              news.type,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // Date
                          Text(
                            news.date,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔹 TITLE (Bottom Left)
                    Positioned(
                      bottom: 15,
                      left: 15,
                      right: 15,
                      child: Text(
                        news.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        // 🔥 DOT INDICATORS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: newsList.asMap().entries.map((entry) {
            int index = entry.key;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentIndex == index ? 20 : 8,
              decoration: BoxDecoration(
                color: _currentIndex == index
                    ? Colors.green
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}