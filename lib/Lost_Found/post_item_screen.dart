import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'lost_found_item.dart';
import 'lost_found_service.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = LostFoundService();
  final _picker = ImagePicker();

  String _type = 'lost';
  String _category = lostFoundCategories.first;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _whatsappController = TextEditingController();
  DateTime _date = DateTime.now();
  final List<File> _images = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  // 🎨 Shared themed input decoration so every field looks consistent
  InputDecoration _decoration(
      BuildContext context, {
        required String label,
        String? hint,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    final cardColor = isDark ? const Color(0xFF0B3D2E) : Colors.white;
    final borderColor = isDark
        ? accent.withValues(alpha: 0.25)
        : const Color(0xFF4CAF50).withValues(alpha: 0.45);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: cardColor,
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600),
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Future<void> _pickImages() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 3 photos.')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    final sheetBg = isDark ? const Color(0xFF0B3D2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? highlight.withValues(alpha: 0.25)
                  : highlight.withValues(alpha: 0.4),
            ),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: highlight),
                title: Text('Take a photo', style: TextStyle(color: textColor)),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: highlight),
                title: Text('Choose from gallery', style: TextStyle(color: textColor)),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() => _images.add(File(picked.path)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: highlight,
              onPrimary: isDark ? Colors.black : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  String? _validateWhatsapp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'WhatsApp number is required';
    }
    final pattern = RegExp(r'^\+[1-9]\d{9,14}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Use international format, e.g. +923001234567';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final secretKey = await _service.postItem(
        type: _type,
        category: _category,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: _date,
        whatsappNumber: _whatsappController.text.trim(),
        images: _images,
      );
      if (!mounted) return;
      await _showSecretKeyDialog(secretKey);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not post item: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showSecretKeyDialog(String key) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    final dialogBg = isDark ? const Color(0xFF0B3D2E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? highlight.withValues(alpha: 0.2)
                : highlight.withValues(alpha: 0.35),
          ),
        ),
        title: Text('Save your secret code', style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You'll need this code to edit or delete this listing later. "
                  "We don't store it anywhere we can read it back to you, so "
                  'write it down or take a screenshot now.',
              style: TextStyle(color: subTextColor),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: highlight.withValues(alpha: isDark ? 0.12 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: highlight.withValues(alpha: 0.5)),
              ),
              child: Text(
                key,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: isDark ? highlight : const Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: highlight),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: highlight,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("I've saved it"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final highlight = isDark ? accent : const Color(0xFF4CAF50);
    final cardColor = isDark ? const Color(0xFF0B3D2E) : Colors.white;
    final borderColor = isDark
        ? accent.withValues(alpha: 0.25)
        : const Color(0xFF4CAF50).withValues(alpha: 0.45);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: isDark ? Colors.white70 : Colors.black87,
                selectedBackgroundColor: highlight,
                selectedForegroundColor: isDark ? Colors.black : Colors.white,
                side: BorderSide(color: borderColor),
              ),
              segments: const [
                ButtonSegment(value: 'lost', label: Text('Lost')),
                ButtonSegment(value: 'found', label: Text('Found')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              dropdownColor: cardColor,
              style: TextStyle(color: textColor),
              decoration: _decoration(context, label: 'Category'),
              items: lostFoundCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: textColor),
              decoration: _decoration(
                context,
                label: 'Title',
                hint: 'e.g. Black wallet, e.g. Blue water bottle',
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: textColor),
              decoration: _decoration(context, label: 'Description'),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              style: TextStyle(color: textColor),
              decoration: _decoration(
                context,
                label: 'Location',
                hint: 'e.g. LGU Library, 2nd floor',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Location is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // 📅 DATE PICKER ROW
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: highlight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Date: ${DateFormat.yMMMd().format(_date)}',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: isDark ? Colors.white60 : Colors.black54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _whatsappController,
              style: TextStyle(color: textColor),
              decoration: _decoration(
                context,
                label: 'WhatsApp number',
                hint: '+923001234567',
              ),
              keyboardType: TextInputType.phone,
              validator: _validateWhatsapp,
            ),
            const SizedBox(height: 16),

            // 🖼 IMAGE PICKER
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.map(
                      (file) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          file,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(file)),
                          child: const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_images.length < 3)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: highlight.withValues(alpha: isDark ? 0.1 : 0.08),
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.add_a_photo_outlined, color: highlight),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 🚀 SUBMIT — uses ElevatedButtonTheme from AppTheme automatically
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
                  : const Text('Post item'),
            ),
          ],
        ),
      ),
    );
  }
}