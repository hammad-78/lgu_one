import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  String selectedCategory = "General";
  bool _isSubmitting = false;

  final List<String> categories = [
    "General",
    "App Improvement",
    "New Feature",
    "Bug Report",
    "Career Section",
    "Other"
  ];

  Future<void> submitRecommendation() async {
    final title = _titleController.text.trim();
    final details = _detailController.text.trim();

    if (title.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('recommendations').add({
        'category': selectedCategory,
        'title': title,
        'details': details,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _detailController.clear();
      setState(() => selectedCategory = "General");

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _SuccessDialog(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to submit: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recommendations"),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🌿 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.feedback, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Share Your Ideas",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Help us improve LGU Connect",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📦 FORM CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [

                      // CATEGORY
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        items: categories.map((String category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // TITLE
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Title",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // DETAILS
                      TextField(
                        controller: _detailController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: "Details",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // SUBMIT BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : submitRecommendation,
                          icon: _isSubmitting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.send),
                          label: Text(_isSubmitting ? "Submitting..." : "Submit Recommendation"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );

    _checkAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // ✅ Auto-close after animation + a short pause
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated circle + checkmark
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _checkAnim,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(44, 44),
                        painter: _CheckPainter(
                          progress: _checkAnim.value,
                          color: primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Submitted!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Thanks for your recommendation.\nWe'll review it shortly.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),

            const SizedBox(height: 28),

          ],
        ),
      ),
    );
  }
}

// Custom painter that draws the checkmark stroke progressively
class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Checkmark path: two segments
    // Segment 1: bottom-left corner of the tick  (0% → 40% of progress)
    // Segment 2: the long right stroke           (40% → 100% of progress)

    final p1 = Offset(size.width * 0.18, size.height * 0.52);
    final p2 = Offset(size.width * 0.42, size.height * 0.74);
    final p3 = Offset(size.width * 0.82, size.height * 0.26);

    final seg1Length = (p2 - p1).distance;
    final seg2Length = (p3 - p2).distance;
    final totalLength = seg1Length + seg2Length;

    final drawn = progress * totalLength;

    if (drawn <= seg1Length) {
      final t = drawn / seg1Length;
      canvas.drawLine(p1, Offset.lerp(p1, p2, t)!, paint);
    } else {
      canvas.drawLine(p1, p2, paint);
      final t = (drawn - seg1Length) / seg2Length;
      canvas.drawLine(p2, Offset.lerp(p2, p3, t)!, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}