import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AddEditEventScreen extends StatefulWidget {
  final String? eventId;
  final Map<String, dynamic>? eventData;

  const AddEditEventScreen({
    super.key,
    this.eventId,
    this.eventData,
  });

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _category = 'University'; // 'University' or 'Lahore'
  DateTime? _selectedDateTime;
  File? _pickedImageFile;
  String? _existingImageUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.eventId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.eventData != null) {
      final data = widget.eventData!;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _locationController.text = data['location'] ?? '';
      _category = (data['category'] == 'Lahore') ? 'Lahore' : 'University';
      _existingImageUrl = data['imageUrl'] as String?;
      if (_existingImageUrl != null) {
        _imageUrlController.text = _existingImageUrl!;
      }

      if (data['eventDate'] != null && data['eventDate'] is Timestamp) {
        _selectedDateTime = (data['eventDate'] as Timestamp).toDate();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: theme.colorScheme.primary),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: theme.colorScheme.primary),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_pickedImageFile != null ||
                  _imageUrlController.text.isNotEmpty ||
                  _existingImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text("Remove Image"),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pickedImageFile = null;
                      _existingImageUrl = null;
                      _imageUrlController.clear();
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDateTime() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final initialDate = _selectedDateTime ?? now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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

    if (pickedDate == null) return;

    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
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

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final fileName = 'events/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Image upload error: $e");
      return null;
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select event date and time"),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;

      if (_pickedImageFile != null) {
        final uploadedUrl = await _uploadImage(_pickedImageFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        imageUrl = _imageUrlController.text.trim();
      } else {
        imageUrl = _existingImageUrl;
      }

      final user = FirebaseAuth.instance.currentUser;
      final eventsRef = FirebaseFirestore.instance.collection('events');

      final dataMap = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'eventDate': Timestamp.fromDate(_selectedDateTime!),
        'location': _locationController.text.trim(),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing) {
        await eventsRef.doc(widget.eventId).update(dataMap);
      } else {
        dataMap['createdBy'] = user?.uid ?? 'unknown';
        dataMap['createdAt'] = FieldValue.serverTimestamp();
        await eventsRef.add(dataMap);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? "Event updated successfully"
                : "Event created successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save event: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pastedUrl = _imageUrlController.text.trim();

    if (_pickedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          _pickedImageFile!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    } else if (pastedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          pastedUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.orange),
              SizedBox(height: 6),
              Text("Invalid Image URL", style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              const Text("Failed to load image"),
            ],
          ),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 44, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            "Tap to upload Cover Image or paste URL below",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Event" : "Add Event"),
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text("Saving event..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image Preview & Upload Container
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _buildImagePreview(context),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Image URL Input Field
                    TextFormField(
                      controller: _imageUrlController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Or Paste Image URL (Optional)",
                        hintText: "https://example.com/image.jpg",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.link, color: theme.colorScheme.primary),
                        suffixIcon: _imageUrlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _imageUrlController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _pickedImageFile = null; // Clear picked file if URL entered
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Event Title *",
                        hintText: "e.g. Annual Sports Gala 2026",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Title is required";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category Selector
                    Text(
                      "Category *",
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'University',
                          label: Text("Within University"),
                          icon: Icon(Icons.school_outlined),
                        ),
                        ButtonSegment(
                          value: 'Lahore',
                          label: Text("Within Lahore"),
                          icon: Icon(Icons.location_city_outlined),
                        ),
                      ],
                      selected: {_category},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _category = newSelection.first;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: theme.colorScheme.primary,
                        selectedForegroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date & Time Picker Button
                    InkWell(
                      onTap: _selectDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDateTime == null
                                    ? "Select Event Date & Time *"
                                    : DateFormat('EEE, dd MMM yyyy - hh:mm a')
                                        .format(_selectedDateTime!),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: _selectedDateTime == null
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  color: _selectedDateTime == null
                                      ? theme.colorScheme.onSurface.withOpacity(0.6)
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Location / Venue *",
                        hintText: "e.g. Main Auditorium, LGU Campus",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                            Icon(Icons.location_on, color: theme.colorScheme.primary),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Location is required";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "Description (Optional)",
                        hintText: "Enter event details, schedule, or notes...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                            Icon(Icons.description, color: theme.colorScheme.primary),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveEvent,
                        icon: Icon(_isEditing ? Icons.check : Icons.add),
                        label: Text(
                          _isEditing ? "Update Event" : "Publish Event",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
