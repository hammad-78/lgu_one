import 'package:flutter/material.dart';
import 'data.dart';
import 'pdf_viewer_screen.dart';

class PaperListScreen extends StatelessWidget {
  final String subject;

  const PaperListScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final papers = subjectData[subject] ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: papers.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.picture_as_pdf_outlined,
                size: 48,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No papers available for $subject yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor),
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: papers.length,
        itemBuilder: (context, index) {
          final paper = papers[index];

          return Card(
            // cardTheme already supplies elevation, color, borderRadius
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: paper.title,
                      url: paper.pdfUrl,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // 📄 PDF ICON BADGE
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: highlight.withValues(alpha: isDark ? 0.14 : 0.1),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: highlight,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            paper.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to view PDF',
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
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