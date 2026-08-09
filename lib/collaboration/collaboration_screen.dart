import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'join_collaboration.dart';

class CollaborationScreen extends StatefulWidget {
  const CollaborationScreen({super.key});

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen> {

  InputDecoration _fieldDecoration(BuildContext context, {required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlight = isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50);
    final cardColor = isDark ? const Color(0xFF0B3D2E) : Colors.white;
    final borderColor = highlight.withValues(alpha: isDark ? 0.4 : 0.5);

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cardColor,
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: highlight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlight = isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50);
    final cardColor = isDark ? const Color(0xFF0B3D2E) : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Collaboration Hub')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.scaffoldBackgroundColor, cardColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // ── HEADER ────────────────────────────────────────────────
                Text(
                  'Connect & Collaborate',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create projects or join existing ones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // ── HERO CARDS ────────────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [

                      // CREATE card
                      Expanded(
                        child: _HeroCard(
                          gradientColors: isDark
                              ? [const Color(0xFFD4AF37), const Color(0xFFB8860B)]
                              : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)],
                          shadowColor: highlight,
                          icon: Icons.add_circle_outline,
                          topLabel: 'CREATE',
                          mainLabel: 'COLLABORATION',
                          subLabel: 'Start a new project',
                          buttonIcon: Icons.arrow_forward_ios,
                          buttonLabel: 'Get Started',
                          onTap: () => _showCreateDialog(context),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // JOIN card
                      Expanded(
                        child: _HeroCard(
                          gradientColors: isDark
                              ? [const Color(0xFF00897B), const Color(0xFF00695C)]
                              : [const Color(0xFF43A047), const Color(0xFF2E7D32)],
                          shadowColor: isDark
                              ? const Color(0xFF00897B)
                              : const Color(0xFF43A047),
                          icon: Icons.people_outline,
                          topLabel: 'JOIN',
                          mainLabel: 'COLLABORATION',
                          subLabel: 'Find existing projects',
                          buttonIcon: Icons.search,
                          buttonLabel: 'Browse Projects',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const JoinCollaborationScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final whatsappController = TextEditingController();
    final membersController = TextEditingController();
    final existingMembersController = TextEditingController();
    final customCategoryController = TextEditingController();
    final customPostController = TextEditingController();
    final secretKeyController = TextEditingController();

    List<String> requiredPosts = [];
    String selectedCategory = 'Tech Project';
    String selectedPost = 'React Developer';
    bool isOtherCategory = false;
    bool isOtherPost = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // ✅ read inside StatefulBuilder — always current, never stale
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final highlight = isDark ? const Color(0xFFD4AF37) : const Color(0xFF4CAF50);
          final dialogBg = isDark ? const Color(0xFF0B3D2E) : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black87;
          final subTextColor = isDark ? Colors.white60 : Colors.black54;

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: highlight.withValues(alpha: 0.35)),
            ),
            title: Text(
              'Create Collaboration',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── TITLE ─────────────────────────────────────────────
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: textColor),
                    decoration: _fieldDecoration(context, label: 'Title'),
                  ),
                  const SizedBox(height: 12),

                  // ── DESCRIPTION ───────────────────────────────────────
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: textColor),
                    decoration: _fieldDecoration(context, label: 'Description'),
                  ),
                  const SizedBox(height: 12),

                  // ── CATEGORY ──────────────────────────────────────────
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    dropdownColor: dialogBg,
                    style: TextStyle(color: textColor),
                    decoration: _fieldDecoration(context, label: 'Category'),
                    items: [
                      'Tech Project', 'Startup', 'Assignment',
                      'Research', 'Debate/MUN', 'Event', 'Other',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setDialogState(() {
                      selectedCategory = v!;
                      isOtherCategory = v == 'Other';
                    }),
                  ),

                  if (isOtherCategory) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customCategoryController,
                      style: TextStyle(color: textColor),
                      decoration: _fieldDecoration(context, label: 'Custom Category'),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── MEMBERS ───────────────────────────────────────────
                  TextField(
                    controller: membersController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: _fieldDecoration(context, label: 'Required Members'),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: existingMembersController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: _fieldDecoration(context, label: 'Existing Members'),
                  ),
                  const SizedBox(height: 12),

                  // ── REQUIRED POST + ADD BUTTON ────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPost,
                          dropdownColor: dialogBg,
                          style: TextStyle(color: textColor),
                          decoration: _fieldDecoration(context, label: 'Required Post'),
                          items: [
                            'React Developer', 'Flutter Developer', 'UI Designer',
                            'Content Writer', 'Video Editor', 'Other',
                          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setDialogState(() {
                            selectedPost = v!;
                            isOtherPost = v == 'Other';
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: highlight,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final finalPost = isOtherPost
                              ? customPostController.text.trim()
                              : selectedPost;
                          if (finalPost.isNotEmpty) {
                            setDialogState(() {
                              requiredPosts.add(finalPost);
                              customPostController.clear();
                            });
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),

                  if (isOtherPost) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customPostController,
                      style: TextStyle(color: textColor),
                      decoration: _fieldDecoration(
                        context,
                        label: 'Custom Required Post',
                      ),
                    ),
                  ],

                  // ── POSTS CHIPS ───────────────────────────────────────
                  if (requiredPosts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: requiredPosts.map((post) => Chip(
                        label: Text(
                          post,
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                        backgroundColor: highlight.withValues(
                          alpha: isDark ? 0.16 : 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: highlight.withValues(alpha: 0.45),
                          ),
                        ),
                        deleteIcon: Icon(
                          Icons.close,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        onDeleted: () => setDialogState(
                              () => requiredPosts.remove(post),
                        ),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── WHATSAPP ──────────────────────────────────────────
                  TextField(
                    controller: whatsappController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: textColor),
                    decoration: _fieldDecoration(context, label: 'WhatsApp Number'),
                  ),
                  const SizedBox(height: 12),

                  // ── SECRET KEY ────────────────────────────────────────
                  TextField(
                    controller: secretKeyController,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    decoration: _fieldDecoration(
                      context,
                      label: 'Secret Key (for editing/deleting later)',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Save this key — you'll need it to edit or delete this listing later.",
                    style: TextStyle(fontSize: 11, color: subTextColor),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: highlight,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final title = titleController.text.trim();
                  final secretKey = secretKeyController.text.trim();
                  final finalCategory = isOtherCategory
                      ? customCategoryController.text.trim()
                      : selectedCategory;

                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title is required')),
                    );
                    return;
                  }
                  if (secretKey.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Secret key is required')),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('collaborations')
                        .doc(title)
                        .set({
                      'info': {
                        'title': title,
                        'description': descriptionController.text.trim(),
                        'category': finalCategory,
                        'requiredMembers':
                        int.tryParse(membersController.text.trim()) ?? 0,
                        'requiredPosts': requiredPosts,
                        'status': 'open',
                        'whatsappNumber': whatsappController.text.trim(),
                        'existingMembers': int.tryParse(
                          existingMembersController.text.trim(),
                        ) ?? 0,
                        'createdAt': FieldValue.serverTimestamp(),
                        'secretKey': secretKey,
                      },
                    });

                    titleController.clear();
                    descriptionController.clear();
                    whatsappController.clear();
                    membersController.clear();
                    customCategoryController.clear();
                    customPostController.clear();
                    existingMembersController.clear();
                    secretKeyController.clear();
                    requiredPosts.clear();

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Collaboration created successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── HERO CARD ───────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Color shadowColor;
  final IconData icon;
  final String topLabel;
  final String mainLabel;
  final String subLabel;
  final IconData buttonIcon;
  final String buttonLabel;
  final VoidCallback onTap;

  const _HeroCard({
    required this.gradientColors,
    required this.shadowColor,
    required this.icon,
    required this.topLabel,
    required this.mainLabel,
    required this.subLabel,
    required this.buttonIcon,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              topLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mainLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(buttonIcon, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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