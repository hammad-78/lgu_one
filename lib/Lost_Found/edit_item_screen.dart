import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'lost_found_item.dart';
import 'lost_found_service.dart';

class EditItemScreen extends StatefulWidget {
  final LostFoundItem item;
  final String secretKey;

  const EditItemScreen({
    super.key,
    required this.item,
    required this.secretKey,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = LostFoundService();
  final _picker = ImagePicker();

  late String _type;
  late String _category;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _whatsappController;
  late DateTime _date;

  String? _existingImageUrl;
  File? _newImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _type = item.type;
    _category = item.category;
    _titleController = TextEditingController(text: item.title);
    _descriptionController = TextEditingController(text: item.description);
    _locationController = TextEditingController(text: item.location);
    _whatsappController = TextEditingController(text: item.whatsappNumber);
    _date = item.date;
    // We only take the first image if multiple existed (legacy)
    if (item.imageUrls.isNotEmpty) {
      _existingImageUrl = item.imageUrls.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
          source: source,
          imageQuality: 50,
          maxWidth: 800
      );
      if (picked != null) {
        setState(() {
          _newImage = File(picked.path);
          _existingImageUrl = null; // Mark existing for removal if we have a new one
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open camera/gallery: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
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

    if (_existingImageUrl == null && _newImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an image.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Logic: If user has a _newImage, we remove ALL old images.
      // If user kept _existingImageUrl, we keep only that one.
      final List<String> removed = [];
      if (_newImage != null || _existingImageUrl == null) {
        removed.addAll(widget.item.imageUrls);
      }

      await _service.updateItem(
        itemId: widget.item.id,
        enteredKey: widget.secretKey,
        type: _type,
        category: _category,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        date: _date,
        whatsappNumber: _whatsappController.text.trim(),
        keptImageUrls: _existingImageUrl != null ? [_existingImageUrl!] : [],
        removedImageUrls: removed,
        newImages: _newImage != null ? [_newImage!] : [],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not update item: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit listing')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
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
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: lostFoundCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Location is required'
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date: ${DateFormat.yMMMd().format(_date)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp number',
                hintText: '+923001234567',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: _validateWhatsapp,
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _newImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_newImage!, fit: BoxFit.cover),
                          ),
                          const Positioned(
                            bottom: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.edit, color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    : _existingImageUrl != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 800,
                                ),
                              ),
                              const Positioned(
                                bottom: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.edit, color: Colors.white),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 40),
                              SizedBox(height: 8),
                              Text('Add photo'),
                            ],
                          ),
              ),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
