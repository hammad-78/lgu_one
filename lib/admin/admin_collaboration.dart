import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCollaboration extends StatefulWidget {
  const AdminCollaboration({super.key});

  @override
  State<AdminCollaboration> createState() => _AdminCollaborationState();
}

class _AdminCollaborationState extends State<AdminCollaboration> {
  final CollectionReference _collabRef =
      FirebaseFirestore.instance.collection('collaborations');

  String _statusFilter = 'All';
  final List<String> _statusOptions = ['All', 'Open', 'Closed'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Collaboration Listings"),
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
              stream: _collabRef
                  .orderBy('info.createdAt', descending: true)
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
                        final info = data['info'] is Map<String, dynamic>
                            ? data['info'] as Map<String, dynamic>
                            : data;
                        final status = (info['status'] ?? '').toString().toLowerCase();
                        return status == _statusFilter.toLowerCase();
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      "No collaborations found",
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final info = data['info'] is Map<String, dynamic>
                        ? data['info'] as Map<String, dynamic>
                        : data;
                    return _buildListingCard(context, doc.id, info);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, String docId, Map<String, dynamic> info) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final String title = info['title'] ?? 'Untitled';
    final String description = info['description'] ?? '';
    final String category = info['category'] ?? '';
    final String status = info['status'] ?? 'open';
    final bool isOpen = status.toLowerCase() == 'open';
    final int requiredMembers = info['requiredMembers'] is int
        ? info['requiredMembers']
        : int.tryParse(info['requiredMembers']?.toString() ?? '0') ?? 0;
    final int existingMembers = info['existingMembers'] is int
        ? info['existingMembers']
        : int.tryParse(info['existingMembers']?.toString() ?? '0') ?? 0;
    final List<dynamic> requiredPosts = info['requiredPosts'] is List
        ? info['requiredPosts'] as List<dynamic>
        : [];
    final String whatsappNumber = info['whatsappNumber'] ?? '';

    final Color statusColor = isOpen ? Colors.green : Colors.redAccent;

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
        padding: const EdgeInsets.all(14),
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
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (description.isNotEmpty)
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.8)),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                if (category.isNotEmpty)
                  _tag(context, Icons.category_outlined, "Category: $category"),
                _tag(context, Icons.people_outline,
                    "Members: $existingMembers/$requiredMembers"),
                if (whatsappNumber.isNotEmpty)
                  _tag(context, Icons.phone_outlined, whatsappNumber),
              ],
            ),
            if (requiredPosts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: requiredPosts.map((post) {
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    label: Text(
                      post.toString(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(docId, info),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit"),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
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
    );
  }

  Widget _tag(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> info) {
    final titleController = TextEditingController(text: info['title'] ?? '');
    final descController = TextEditingController(text: info['description'] ?? '');
    final categoryController =
        TextEditingController(text: info['category'] ?? '');
    final reqMembersController = TextEditingController(
        text: (info['requiredMembers'] ?? 0).toString());
    final existMembersController = TextEditingController(
        text: (info['existingMembers'] ?? 0).toString());
    final whatsappController =
        TextEditingController(text: info['whatsappNumber'] ?? '');
    final postsController = TextEditingController(
      text: (info['requiredPosts'] is List)
          ? (info['requiredPosts'] as List).join(', ')
          : '',
    );
    String status = info['status'] ?? 'open';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Collaboration"),
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
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: existMembersController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: "Existing Members"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: reqMembersController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: "Required Members"),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: postsController,
                      decoration: const InputDecoration(
                        labelText: "Required Roles/Posts (comma separated)",
                      ),
                    ),
                    TextField(
                      controller: whatsappController,
                      decoration:
                          const InputDecoration(labelText: "WhatsApp Number"),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status.toLowerCase(),
                      decoration: const InputDecoration(labelText: "Status"),
                      items: const [
                        DropdownMenuItem(value: 'open', child: Text("Open")),
                        DropdownMenuItem(value: 'closed', child: Text("Closed")),
                      ],
                      onChanged: (value) {
                        setDialogState(() => status = value ?? status);
                      },
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
                    List<String> updatedPosts = postsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    await _updateCollaboration(docId, {
                      'info.title': titleController.text.trim(),
                      'info.description': descController.text.trim(),
                      'info.category': categoryController.text.trim(),
                      'info.requiredMembers':
                          int.tryParse(reqMembersController.text.trim()) ?? 0,
                      'info.existingMembers':
                          int.tryParse(existMembersController.text.trim()) ?? 0,
                      'info.requiredPosts': updatedPosts,
                      'info.whatsappNumber': whatsappController.text.trim(),
                      'info.status': status,
                    });
                    if (context.mounted) Navigator.pop(context);
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

  Future<void> _updateCollaboration(
      String docId, Map<String, dynamic> updates) async {
    try {
      await _collabRef.doc(docId).update(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Collaboration updated")),
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
          title: const Text("Delete Collaboration"),
          content: const Text(
              "Are you sure you want to delete this collaboration? This cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCollaboration(docId);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCollaboration(String docId) async {
    try {
      await _collabRef.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Collaboration deleted")),
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
