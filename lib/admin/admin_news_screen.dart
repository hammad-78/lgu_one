import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lgu_one/news_section/news_model.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final _formKey = GlobalKey<FormState>();
  final CollectionReference _newsRef =
      FirebaseFirestore.instance.collection('news');

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedType = 'Admission';
  final List<String> _typeOptions = ['Admission', 'Event', 'Notice', 'Drive', 'General'];

  File? _pickedImageFile;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    // Default date to today formatted as '12 Apr 2026'
    _dateController.text = DateFormat('dd MMM yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedImageFile = File(picked.path);
          _imageUrlController.clear(); // Clear text URL if file picked
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick image: $e")),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final theme = Theme.of(context);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('dd MMM yyyy').format(pickedDate);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = 'news_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('news_images')
          .child(fileName);

      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Storage Upload Error: $e");
      return null;
    }
  }

  Future<void> _publishNews() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if an image is provided (either file picked or URL entered)
    String imageUrl = _imageUrlController.text.trim();

    if (_pickedImageFile == null && imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an image file or enter an image URL"),
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      // If file picked, upload to Firebase Storage first
      if (_pickedImageFile != null) {
        final uploadedUrl = await _uploadImage(_pickedImageFile!);
        if (uploadedUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to upload news image. Please try again."),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isPublishing = false);
          return;
        }
        imageUrl = uploadedUrl;
      }

      // Save to Firestore collection 'news'
      await _newsRef.add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image': imageUrl,
        'type': _selectedType,
        'date': _dateController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("News published successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to publish news: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    setState(() {
      _pickedImageFile = null;
      _selectedType = 'Admission';
      _dateController.text = DateFormat('dd MMM yyyy').format(DateTime.now());
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("News Management"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 CREATE NEWS CARD FORM
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_location_alt_outlined, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Publish New Announcement",
                              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24, color: theme.dividerColor.withOpacity(0.5)),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: const InputDecoration(
                          labelText: "News Title *",
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Title is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: const InputDecoration(
                          labelText: "News Description *",
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Description is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Category & Date (Responsive Layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;

                          final typeDropdown = DropdownButtonFormField<String>(
                            value: _selectedType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: "Category / Type",
                              prefixIcon: Icon(Icons.label_outlined),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                            ),
                            items: _typeOptions
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedType = val);
                              }
                            },
                          );

                          final datePicker = TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: _selectDate,
                            style: TextStyle(color: theme.colorScheme.onSurface),
                            decoration: const InputDecoration(
                              labelText: "Date *",
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Date is required";
                              }
                              return null;
                            },
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                typeDropdown,
                                const SizedBox(height: 14),
                                datePicker,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: typeDropdown),
                              const SizedBox(width: 12),
                              Expanded(child: datePicker),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Image Input Section
                      Text(
                        "News Banner Image *",
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // Image Preview or Picker Buttons
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        constraints: const BoxConstraints(minHeight: 120),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                        ),
                        child: _pickedImageFile != null
                            ? Stack(
                                children: [
                                  SizedBox(
                                    height: 140,
                                    width: double.infinity,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _pickedImageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 16,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close,
                                            size: 18, color: Colors.white),
                                        onPressed: () {
                                          setState(() => _pickedImageFile = null);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _pickImage(ImageSource.gallery),
                                        icon: const Icon(Icons.photo_library,
                                            size: 18),
                                        label: const Text("Gallery"),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _pickImage(ImageSource.camera),
                                        icon: const Icon(Icons.camera_alt,
                                            size: 18),
                                        label: const Text("Camera"),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "OR enter Image URL below",
                                    style: TextStyle(
                                        fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),

                      // Image URL Direct Input
                      TextFormField(
                        controller: _imageUrlController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        onChanged: (val) {
                          if (val.isNotEmpty && _pickedImageFile != null) {
                            setState(() => _pickedImageFile = null);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: "Direct Image URL (Optional fallback)",
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Publish Button
                      ElevatedButton(
                        onPressed: _isPublishing ? null : _publishNews,
                        child: _isPublishing
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : const Text(
                                "Publish News",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 MANAGED NEWS LIST HEADER
            Text(
              "Published News Items",
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Real-time List of Firestore news docs
            StreamBuilder<QuerySnapshot>(
              stream: _newsRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading news: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No published news yet",
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final news = NewsModel.fromDocument(doc);
                    return _buildNewsItemCard(context, news);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItemCard(BuildContext context, NewsModel news) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: theme.colorScheme.primary.withOpacity(0.2)) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: news.image.isNotEmpty
                  ? Image.network(
                      news.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            news.type,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          news.date,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    news.description,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Actions: Edit / Delete
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditDialog(news),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Edit"),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(news.id),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text("Delete"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(NewsModel news) {
    final titleEditController = TextEditingController(text: news.title);
    final descEditController = TextEditingController(text: news.description);
    final imageEditController = TextEditingController(text: news.image);
    final dateEditController = TextEditingController(text: news.date);
    String typeValue = news.type;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final options = {'Admission', 'Event', 'Notice', 'Drive', 'General', typeValue}.toList();

            return AlertDialog(
              title: const Text("Edit News"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleEditController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    TextField(
                      controller: descEditController,
                      decoration: const InputDecoration(labelText: "Description"),
                      maxLines: 3,
                    ),
                    DropdownButtonFormField<String>(
                      value: typeValue,
                      decoration: const InputDecoration(labelText: "Category / Type"),
                      items: options
                          .map((opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => typeValue = val);
                        }
                      },
                    ),
                    TextField(
                      controller: dateEditController,
                      decoration: const InputDecoration(labelText: "Date"),
                    ),
                    TextField(
                      controller: imageEditController,
                      decoration: const InputDecoration(labelText: "Image URL"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (news.id != null) {
                      await _newsRef.doc(news.id).update({
                        'title': titleEditController.text.trim(),
                        'description': descEditController.text.trim(),
                        'type': typeValue,
                        'date': dateEditController.text.trim(),
                        'image': imageEditController.text.trim(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("News updated")),
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String? docId) {
    if (docId == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete News"),
          content: const Text(
              "Are you sure you want to delete this news item? This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await _newsRef.doc(docId).delete();
                messenger.showSnackBar(
                  const SnackBar(content: Text("News item deleted")),
                );
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
