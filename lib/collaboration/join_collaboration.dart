import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skeletonizer/skeletonizer.dart';

class JoinCollaborationScreen extends StatelessWidget {
  const JoinCollaborationScreen({super.key});


  /// VERIFY SECRET KEY, THEN RUN ACTION
  void verifySecretKey(
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
                    const SnackBar(
                      content: Text("Incorrect Secret Key"),
                    ),
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

  /// OPEN WHATSAPP
  Future<void> openWhatsApp(String number) async {

    String formattedNumber = number
        .replaceAll('+', '')
        .replaceAll(' ', '');

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$formattedNumber",
    );

    try {

      await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );

    } catch (e) {

      debugPrint("Could not launch WhatsApp: $e");
    }
  }

  /// EDIT DIALOG
  void showEditDialog(
      BuildContext context,
      String docId,
      Map<String, dynamic> info,
      ) {

    final titleController =
    TextEditingController(text: info['title']);

    final descController =
    TextEditingController(text: info['description']);

    final categoryController =
    TextEditingController(text: info['category']);

    final whatsappController =
    TextEditingController(text: info['whatsappNumber']);

    final requiredMembersController =
    TextEditingController(
      text: info['requiredMembers'].toString(),
    );

    final existingMembersController =
    TextEditingController(
      text: info['existingMembers'].toString(),
    );

    final statusController =
    TextEditingController(text: info['status']);

    final postsController =
    TextEditingController(
      text: (info['requiredPosts'] as List<dynamic>)
          .join(', '),
    );

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),

          title: const Text(
            "Edit Collaboration",
          ),

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
                    labelText:
                    "Required Posts (comma separated)",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                /// STATUS
                TextField(
                  controller: statusController,
                  decoration: const InputDecoration(
                    labelText: "Status",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                /// WHATSAPP NUMBER
                TextField(
                  controller: whatsappController,
                  keyboardType: TextInputType.phone,
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

                List<String> updatedPosts =
                postsController.text
                    .split(',')
                    .map(
                      (e) => e.trim(),
                )
                    .where(
                      (e) => e.isNotEmpty,
                )
                    .toList();

                await FirebaseFirestore.instance
                    .collection('collaborations')
                    .doc(docId)
                    .update({

                  'info.title':
                  titleController.text.trim(),

                  'info.description':
                  descController.text.trim(),

                  'info.category':
                  categoryController.text.trim(),

                  'info.requiredMembers':
                  int.tryParse(
                    requiredMembersController.text.trim(),
                  ) ??
                      0,

                  'info.existingMembers':
                  int.tryParse(
                    existingMembersController.text.trim(),
                  ) ??
                      0,

                  'info.requiredPosts':
                  updatedPosts,

                  'info.status':
                  statusController.text.trim(),

                  'info.whatsappNumber':
                  whatsappController.text.trim(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Collaboration Updated",
                    ),
                  ),
                );
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Join Collaboration",
        ),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection('collaborations')
            .orderBy(
          'info.createdAt',
          descending: true,
        )
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return ListView.builder(

              padding: const EdgeInsets.all(12),

              itemCount: 6,

              itemBuilder: (context, index) {

                return Card(

                  elevation: 4,

                  margin: const EdgeInsets.only(
                    bottom: 15,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),

                  child: Skeletonizer(

                    enabled: true,

                    effect: ShimmerEffect(
                      duration: const Duration(seconds: 2),
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                    ),

                    child: Padding(

                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          /// TITLE
                          const Text(
                            "Collaboration Project Title",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// DESCRIPTION
                          const Text(
                            "This is a fake description for loading skeleton effect in the collaboration card section.",
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// CATEGORY
                          const Row(
                            children: [

                              Skeleton.ignore(
                                child: Icon(Icons.category),
                              ),

                              SizedBox(width: 8),

                              Text(
                                "Category: Tech Project",
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// MEMBERS
                          const Row(
                            children: [

                              Skeleton.ignore(
                                child: Icon(Icons.people),
                              ),

                              SizedBox(width: 8),

                              Text(
                                "Members: 2/5",
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// STATUS
                          const Row(
                            children: [

                              Skeleton.ignore(
                                child: Icon(Icons.info),
                              ),

                              SizedBox(width: 8),

                              Text(
                                "Status: Open",
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          /// POSTS TITLE
                          const Text(
                            "Required Posts:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          /// POSTS
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,

                            children: List.generate(
                              3,
                                  (index) => const Chip(
                                label: Text(
                                  "Flutter Developer",
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// WHATSAPP BUTTON
                          SizedBox(
                            width: double.infinity,

                            child: ElevatedButton.icon(

                              onPressed: null,

                              icon: const Icon(Icons.chat),

                              label: const Text(
                                "Contact on WhatsApp",
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// OWNER CONTROLS
                          Row(
                            children: [

                              Expanded(
                                child: OutlinedButton.icon(

                                  onPressed: null,

                                  icon: const Icon(Icons.edit),

                                  label: const Text("Edit"),
                                ),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: ElevatedButton.icon(

                                  onPressed: null,

                                  icon: const Icon(Icons.delete),

                                  label: const Text("Delete"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return const Center(
              child: Text(
                "No Collaborations Found",
              ),
            );
          }

          final collaborations =
              snapshot.data!.docs;

          return ListView.builder(

            padding: const EdgeInsets.all(12),

            itemCount: collaborations.length,

            itemBuilder: (context, index) {

              final doc = collaborations[index];

              final info =
              doc['info'] as Map<String, dynamic>;

              return Card(

                elevation: 4,

                margin: const EdgeInsets.only(
                  bottom: 15,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      /// TITLE
                      Text(
                        info['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// DESCRIPTION
                      Text(
                        info['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// CATEGORY
                      Row(
                        children: [

                          const Icon(Icons.category),

                          const SizedBox(width: 8),

                          Text(
                            "Category: ${info['category']}",
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// MEMBERS
                      Row(
                        children: [

                          const Icon(Icons.people),

                          const SizedBox(width: 8),

                          Text(
                            "Members: "
                                "${info['existingMembers']}"
                                "/"
                                "${info['requiredMembers']}",
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// STATUS
                      Row(
                        children: [

                          const Icon(Icons.info),

                          const SizedBox(width: 8),

                          Text(
                            "Status: ${info['status']}",
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      /// REQUIRED POSTS TITLE
                      const Text(
                        "Required Posts:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// POSTS
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,

                        children:
                        (info['requiredPosts']
                        as List<dynamic>)
                            .map(
                              (post) => Chip(
                            label: Text(
                              post.toString(),
                            ),
                          ),
                        )
                            .toList(),
                      ),

                      const SizedBox(height: 20),

                      /// WHATSAPP BUTTON
                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton.icon(

                          onPressed: () {

                            openWhatsApp(
                              info['whatsappNumber'],
                            );
                          },

                          icon: const Icon(Icons.chat),

                          label: const Text(
                            "Contact on WhatsApp",
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// OWNER CONTROLS
                      const SizedBox(height: 10),

                      /// EDIT / DELETE CONTROLS
                      Row(
                        children: [

                          /// EDIT
                          Expanded(
                            child: OutlinedButton.icon(

                              onPressed: () {
                                verifySecretKey(
                                  context,
                                  info['secretKey'] ?? '',
                                      () {
                                    showEditDialog(
                                      context,
                                      doc.id,
                                      info,
                                    );
                                  },
                                );
                              },

                              icon: const Icon(Icons.edit),

                              label: const Text("Edit"),
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// DELETE
                          Expanded(
                            child: ElevatedButton.icon(

                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),

                              onPressed: () {
                                verifySecretKey(
                                  context,
                                  info['secretKey'] ?? '',
                                      () async {
                                    await FirebaseFirestore.instance
                                        .collection('collaborations')
                                        .doc(doc.id)
                                        .delete();
                                  },
                                );
                              },

                              icon: const Icon(Icons.delete),

                              label: const Text("Delete"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}