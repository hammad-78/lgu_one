import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lgu_one/jobs/model.dart';

class AdminJobsScreen extends StatefulWidget {
  const AdminJobsScreen({super.key});

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  final _formKey = GlobalKey<FormState>();
  final CollectionReference _jobsRef =
      FirebaseFirestore.instance.collection('jobs');

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _imageUrlController = TextEditingController();

  File? _pickedImageFile;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pickedImageFile = File(picked.path);
          _imageUrlController.clear();
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

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = 'job_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('job_images')
          .child(fileName);

      final uploadTask = await storageRef.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Storage Upload Error: $e");
      return null;
    }
  }

  Future<void> _publishJob() async {
    if (!_formKey.currentState!.validate()) return;

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
      if (_pickedImageFile != null) {
        final uploadedUrl = await _uploadImage(_pickedImageFile!);
        if (uploadedUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to upload job banner image. Please try again."),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isPublishing = false);
          return;
        }
        imageUrl = uploadedUrl;
      }

      await _jobsRef.add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'link': _linkController.text.trim(),
        'image': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Job/Internship published successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to publish job: $e"),
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
    _linkController.clear();
    _imageUrlController.clear();
    setState(() {
      _pickedImageFile = null;
    });
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jobs & Internships"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 FORM CARD
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
                          Icon(Icons.work_outline, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Publish Opportunity",
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
                          labelText: "Job / Opportunity Title *",
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
                          labelText: "Job Description *",
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

                      // Apply Link Field
                      TextFormField(
                        controller: _linkController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: const InputDecoration(
                          labelText: "Apply Link / URL *",
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Apply link is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Image Input Section
                      Text(
                        "Opportunity Banner Image *",
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),

                      // Image Preview or Picker
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

                      // Direct Image URL Field
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
                          prefixIcon: Icon(Icons.image_search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isPublishing ? null : _publishJob,
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
                                "Publish Opportunity",
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

            // 🔹 MANAGED JOBS LIST HEADER
            Text(
              "Published Opportunities",
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Real-time List of Firestore jobs docs
            StreamBuilder<QuerySnapshot>(
              stream: _jobsRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error loading jobs: ${snapshot.error}"));
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
                        "No published jobs or internships yet",
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
                    final job = Job.fromDocument(doc);
                    return _buildJobItemCard(context, job);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobItemCard(BuildContext context, Job job) {
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
              child: job.image.isNotEmpty
                  ? Image.network(
                      job.image,
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
                      child: const Icon(Icons.work, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.description,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Link: ${job.link}",
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    maxLines: 1,
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
                        onPressed: () => _showEditDialog(job),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Edit"),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(job.id),
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

  void _showEditDialog(Job job) {
    final titleEditController = TextEditingController(text: job.title);
    final descEditController = TextEditingController(text: job.description);
    final linkEditController = TextEditingController(text: job.link);
    final imageEditController = TextEditingController(text: job.image);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Opportunity"),
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
                TextField(
                  controller: linkEditController,
                  decoration: const InputDecoration(labelText: "Apply Link"),
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
                if (job.id != null) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  await _jobsRef.doc(job.id).update({
                    'title': titleEditController.text.trim(),
                    'description': descEditController.text.trim(),
                    'link': linkEditController.text.trim(),
                    'image': imageEditController.text.trim(),
                  });
                  messenger.showSnackBar(
                    const SnackBar(content: Text("Opportunity updated")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
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
          title: const Text("Delete Opportunity"),
          content: const Text(
              "Are you sure you want to delete this opportunity? This cannot be undone."),
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
                await _jobsRef.doc(docId).delete();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Opportunity deleted")),
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
