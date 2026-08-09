import 'package:flutter/material.dart';
import 'data.dart';
import 'paper_list_screen.dart';

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = subjectData.keys.toList();
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color; // already correct per-mode from AppTheme
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Subjects")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final paperCount = subjectData[subject]?.length ?? 0;

          return Card(
            // cardTheme already supplies elevation, color, borderRadius
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaperListScreen(subject: subject),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // 📚 ICON BADGE — uses theme's iconTheme color directly
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: iconColor?.withValues(alpha: isDark ? 0.14 : 0.1),
                      ),
                      child: Icon(Icons.book, color: iconColor, size: 24),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // headlineMedium is already correctly colored per theme
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            paperCount == 1 ? '1 paper' : '$paperCount papers',
                            // bodyMedium is also already correctly colored per theme
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: iconColor?.withValues(alpha: 0.55),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}