import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Lost_Found/lost_found_item.dart';
import '../Lost_Found/lost_found_service.dart';

class AdminLostFound extends StatefulWidget {
  const AdminLostFound({super.key});

  @override
  State<AdminLostFound> createState() => _AdminLostFoundState();
}

class _AdminLostFoundState extends State<AdminLostFound> {
  final CollectionReference _lostFoundRef =
      FirebaseFirestore.instance.collection('lost_found_items');
  final _service = LostFoundService();

  String _statusFilter = 'Pending';

  final List<String> _statusOptions = [
    'Pending',
    'Active',
    'Resolved',
    'Rejected',
    'All'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin: Lost & Found"),
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
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurface,
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
                        final status = (data['status'] ?? 'pending').toString().toLowerCase();
                        return status == _statusFilter.toLowerCase();
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      "No $_statusFilter listings found",
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildListingCard(context, doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String title = data['title'] ?? 'Untitled';
    final String description = data['description'] ?? '';
    final String type = data['type'] ?? 'lost';
    final String status = data['status'] ?? 'pending';
    final String category = data['category'] ?? '';
    final String location = data['location'] ?? '';
    final List<dynamic> imageUrls = data['imageUrls'] ?? [];
    final String imageUrl = imageUrls.isNotEmpty ? imageUrls.first : '';

    Color typeColor = type.toLowerCase() == 'found' ? Colors.blue : Colors.red;

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
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
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
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
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
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              type.toUpperCase(),
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
                          style: TextStyle(
                              fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (category.isNotEmpty)
                            _tag(context, Icons.category_outlined, category),
                          if (location.isNotEmpty)
                            _tag(context, Icons.location_on_outlined, location),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 20, color: theme.dividerColor.withOpacity(0.5)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(docId, data),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                ),
                const SizedBox(width: 8),
                if (status == 'pending') ...[
                  ElevatedButton.icon(
                    onPressed: () => _service.updateItemStatus(docId, 'active'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _service.updateItemStatus(docId, 'rejected'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (status == 'rejected')
                  ElevatedButton.icon(
                    onPressed: () => _service.updateItemStatus(docId, 'active'),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text("Restore"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _confirmDelete(docId),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: data['title'] ?? '');
    final descController = TextEditingController(text: data['description'] ?? '');
    final categoryController = TextEditingController(text: data['category'] ?? '');
    final locationController = TextEditingController(text: data['location'] ?? '');
    final whatsappController = TextEditingController(text: data['whatsappNumber'] ?? '');
    String type = data['type'] ?? 'lost';
    String status = data['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Listing (Admin)"),
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
                      decoration: const InputDecoration(labelText: "Description"),
                      maxLines: 3,
                    ),
                    DropdownButtonFormField<String>(
                      value: lostFoundCategories.contains(categoryController.text) 
                          ? categoryController.text 
                          : lostFoundCategories.first,
                      decoration: const InputDecoration(labelText: "Category"),
                      items: lostFoundCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => categoryController.text = v ?? categoryController.text,
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: "Location"),
                    ),
                    TextField(
                      controller: whatsappController,
                      decoration: const InputDecoration(labelText: "WhatsApp Number"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type.toLowerCase(),
                      decoration: const InputDecoration(labelText: "Type"),
                      items: const [
                        DropdownMenuItem(value: 'lost', child: Text("Lost")),
                        DropdownMenuItem(value: 'found', child: Text("Found")),
                      ],
                      onChanged: (value) => setDialogState(() => type = value ?? type),
                    ),
                    DropdownButtonFormField<String>(
                      value: status.toLowerCase(),
                      decoration: const InputDecoration(labelText: "Status"),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text("Pending")),
                        DropdownMenuItem(value: 'active', child: Text("Active")),
                        DropdownMenuItem(value: 'resolved', child: Text("Resolved")),
                        DropdownMenuItem(value: 'rejected', child: Text("Rejected")),
                      ],
                      onChanged: (value) => setDialogState(() => status = value ?? status),
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
                    await _lostFoundRef.doc(docId).update({
                      'title': titleController.text.trim(),
                      'description': descController.text.trim(),
                      'category': categoryController.text.trim(),
                      'location': locationController.text.trim(),
                      'whatsappNumber': whatsappController.text.trim(),
                      'type': type,
                      'status': status,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Listing updated successfully")),
                      );
                    }
                  },
                  child: const Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Listing"),
          content: const Text(
              "Are you sure you want to delete this listing from the database? This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteListing(docId);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteListing(String docId) async {
    try {
      await _lostFoundRef.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing permanently deleted")),
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
