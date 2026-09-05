import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddEditSocietyScreen extends StatefulWidget {
  final String? societyId;
  final Map<String, dynamic>? societyData;

  const AddEditSocietyScreen({
    super.key,
    this.societyId,
    this.societyData,
  });

  @override
  State<AddEditSocietyScreen> createState() => _AddEditSocietyScreenState();
}

class _AddEditSocietyScreenState extends State<AddEditSocietyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _memberCountController = TextEditingController();
  final _presidentPhoneController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.societyId != null;

  @override
  void initState() {
    super.initState();
    final data = widget.societyData;
    if (_isEditing && data != null) {
      _nameController.text = (data['name'] ?? '').toString();
      _descriptionController.text = (data['description'] ?? '').toString();
      _imageUrlController.text = (data['imageUrl'] ?? '').toString();
      _memberCountController.text = (data['memberCount'] ?? 0).toString();
      _presidentPhoneController.text = (data['presidentPhone'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _memberCountController.dispose();
    _presidentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveSociety() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
        'memberCount': int.parse(_memberCountController.text.trim()),
        'presidentPhone': _presidentPhoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final societies = FirebaseFirestore.instance.collection('societies');
      if (_isEditing) {
        await societies.doc(widget.societyId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await societies.add(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Society updated' : 'Society added')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save society: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Society' : 'Add Society')),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Society name'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _memberCountController,
                      decoration: const InputDecoration(labelText: 'Member count'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value.trim()) == null) {
                          return 'Enter a whole number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _presidentPhoneController,
                      decoration: const InputDecoration(labelText: 'President WhatsApp number'),
                      keyboardType: TextInputType.phone,
                      validator: _required,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saveSociety,
                        icon: const Icon(Icons.save),
                        label: Text(_isEditing ? 'Save Changes' : 'Add Society'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}