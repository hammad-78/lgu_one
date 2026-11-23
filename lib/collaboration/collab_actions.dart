import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lgu_one/auth/lgu_email_gate.dart';
import 'package:lgu_one/collaboration/collab_owner.dart';
import 'package:lgu_one/ventures/share_idea_screen.dart';
import 'package:lgu_one/ventures/ventures_service.dart';
import 'package:lgu_one/utils/flushbar.dart';
import 'package:lgu_one/utils/pakistani_phone_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Creating, editing, deleting and contacting a collaboration post.
class CollabActions {
  CollabActions._();

  /// Contact the team on WhatsApp. Asks for an LGU email first, as the board
  /// always has, so numbers aren't handed to anyone who opens the app.
  static Future<void> contact(BuildContext context, String number) async {
    if (!await LguEmailGate.ensureVerified(context)) return;
    await _openWhatsApp(number);
  }

  /// "Share an idea": signs the student in if needed, then opens the form.
  static Future<void> startCreate(BuildContext context) async {
    final student = await CollabOwner.requireStudent(context);
    if (student == null || !context.mounted) return;
    await shareIdea(context, student);
  }

  static void _verifySecretKey(
    BuildContext context,
    String storedKey,
    VoidCallback onVerified,
  ) {
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Enter Secret Key"),
          content: TextField(
            controller: keyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Secret Key",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (keyController.text.trim() == storedKey) {
                  Navigator.pop(context);
                  onVerified();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Incorrect Secret Key")),
                  );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  /// Owner's own post: no key needed. Older posts: ask for the secret key.
  static void asOwner(
    BuildContext context,
    Map<String, dynamic> info,
    VoidCallback action,
  ) {
    if (CollabOwner.isMine(info)) {
      action();
    } else {
      _verifySecretKey(context, (info['secretKey'] ?? '').toString(), action);
    }
  }

  /// Asks, then deletes.
  static Future<void> confirmDelete(BuildContext context, String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('It is removed from the board for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await VenturesService.deletePost(docId);
    } catch (_) {
      if (context.mounted) {
        await showFlushbar(
          context,
          'Could not delete. Try again.',
          color: Colors.red.shade900,
        );
      }
    }
  }

  /// OPEN WHATSAPP
  static Future<void> _openWhatsApp(String number) async {
    String formattedNumber = number.replaceAll('+', '').replaceAll(' ', '');

    final Uri whatsappUrl = Uri.parse("https://wa.me/$formattedNumber");

    try {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch WhatsApp: $e");
    }
  }

  /// EDIT DIALOG
  static void showEdit(
    BuildContext context,
    String docId,
    Map<String, dynamic> info,
  ) {
    final pageContext = context;
    final titleController = TextEditingController(text: info['title']);

    final descController = TextEditingController(text: info['description']);

    final categoryController = TextEditingController(text: info['category']);

    final whatsappController = TextEditingController(
      text: info['whatsappNumber'],
    );

    final requiredMembersController = TextEditingController(
      text: info['requiredMembers'].toString(),
    );

    final existingMembersController = TextEditingController(
      text: info['existingMembers'].toString(),
    );

    final postsController = TextEditingController(
      text: (info['requiredPosts'] as List<dynamic>).join(', '),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: const Text("Edit Collaboration"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                /// TITLE
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                /// DESCRIPTION
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                /// CATEGORY
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                /// REQUIRED MEMBERS
                TextField(
                  controller: requiredMembersController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Required Members",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                /// EXISTING MEMBERS
                TextField(
                  controller: existingMembersController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Existing Members",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                /// REQUIRED POSTS
                TextField(
                  controller: postsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Required Posts (comma separated)",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                /// WHATSAPP NUMBER
                TextField(
                  controller: whatsappController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PakistaniPhoneFormatter()],
                  decoration: const InputDecoration(
                    labelText: "WhatsApp Number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            /// CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            /// UPDATE
            ElevatedButton(
              onPressed: () async {
                List<String> updatedPosts = postsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                await FirebaseFirestore.instance
                    .collection('collaborations')
                    .doc(docId)
                    .update({
                      'info.title': titleController.text.trim(),

                      'info.description': descController.text.trim(),

                      'info.category': categoryController.text.trim(),

                      'info.requiredMembers':
                          int.tryParse(requiredMembersController.text.trim()) ??
                          0,

                      'info.existingMembers':
                          int.tryParse(existingMembersController.text.trim()) ??
                          0,

                      'info.requiredPosts': updatedPosts,

                      'info.whatsappNumber': canonicalPakistaniPhone(
                        whatsappController.text.trim(),
                      ),
                    });

                if (context.mounted) {
                  Navigator.pop(context);
                  await showFlushbar(
                    pageContext,
                    'Collaboration updated successfully',
                    color: Colors.green.shade900,
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}
