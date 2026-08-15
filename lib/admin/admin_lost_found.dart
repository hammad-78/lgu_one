import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminLostFound extends StatefulWidget {
  const AdminLostFound({super.key});

  @override
  State<AdminLostFound> createState() => _AdminLostFoundState();
}

class _AdminLostFoundState extends State<AdminLostFound> {
  final CollectionReference _lostFoundRef =
  FirebaseFirestore.instance.collection('lost_found_items');

  String _statusFilter = 'All';

  final List<String> _statusOptions = ['All', 'Lost', 'Found', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Lost & Found Listings"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statusOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = _statusOptions[index];
                  final isSelected = _statusFilter == option;
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _statusFilter = option);
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _lostFoundRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = _statusFilter == 'All'
                    ? docs
                    : docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return (data['status'] ?? '') == _statusFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      "No listings found",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildListingCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(String docId, Map<String, dynamic> data) {
    final String title = data['title'] ?? 'Untitled';
    final String description = data['description'] ?? '';
    final String status = data['status'] ?? 'Lost';
    final String category = data['category'] ?? '';
    final String location = data['location'] ?? '';
    final String imageUrl = data['imageUrl'] ?? '';
    final String postedBy = data['postedBy'] ?? 'Unknown';

    Color statusColor;
    switch (status) {
      case 'Found':
        statusColor = Colors.blue;
        break;
      case 'Resolved':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.grey),
                ),
              )
                  : Container(
                width: 72,
                height: 72,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (category.isNotEmpty)
                        _tag(Icons.category_outlined, category),
                      if (location.isNotEmpty)
                        _tag(Icons.location_on_outlined, location),
                      _tag(Icons.person_outline, postedBy),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _showEditDialog(docId, data),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Edit"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(docId),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text("Delete"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
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

  Widget _tag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.black54),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descController =
    TextEditingController(text: data['description'] ?? '');
    final categoryController =
    TextEditingController(text: data['category'] ?? '');
    final locationController =
    TextEditingController(text: data['location'] ?? '');
    String status = data['status'] ?? 'Lost';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Listing"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    TextField(
                      controller: descController,
                      decoration:
                      const InputDecoration(labelText: "Description"),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: categoryController,
                      decoration:
                      const InputDecoration(labelText: "Category"),
                    ),
                    TextField(
                      controller: locationController,
                      decoration:
                      const InputDecoration(labelText: "Location"),
                    ),
                    const SizedBox(height: 12),
                    Builder(builder: (context) {
                      // Always include whatever value is currently stored,
                      // even if it doesn't match one of the known options,
                      // so the dropdown never throws on unexpected data.
                      final knownOptions = ['Lost', 'Found', 'Resolved'];
                      final dropdownOptions = {
                        ...knownOptions,
                        status,
                      }.toList();

                      return DropdownButtonFormField<String>(
                        value: status,
                        decoration:
                        const InputDecoration(labelText: "Status"),
                        items: dropdownOptions
                            .map((option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => status = value ?? status);
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await _updateListing(docId, {
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'category': categoryController.text.trim(),
                      'location': locationController.text.trim(),
                      'status': status,
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateListing(
      String docId, Map<String, dynamic> updates) async {
    try {
      await _lostFoundRef.doc(docId).update(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing updated")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: $e")),
        );
      }
    }
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Listing"),
          content: const Text(
              "Are you sure you want to delete this listing? This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteListing(docId);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteListing(String docId) async {
    try {
      // Note: this only deletes the Firestore document.
      // If you store images in Firebase Storage, delete them there too
      // using the stored imageUrl/storage path before or after this call.
      await _lostFoundRef.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing deleted")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
      }
    }
  }
}