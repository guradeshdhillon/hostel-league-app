import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rolebase/ManagementDashboard.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:rolebase/history_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';


class TopStories extends StatefulWidget {
  final bool isAdmin;
  const TopStories({Key? key, this.isAdmin = false}) : super(key: key);

  @override
  _TopStoriesState createState() => _TopStoriesState();
}

class _TopStoriesState extends State<TopStories> {
  FirebaseStorage storage = FirebaseStorage.instance;
  List<String> uploadedFiles = [];
  bool isLoading = false;
  final picker = ImagePicker();
  File? selectedFile;
  String fileUrl = '';
  final messageController = TextEditingController();
  final titleController = TextEditingController(); // Added title controller

  @override
  void initState() {
    super.initState();
    fetchFiles();
    // requestPermissions();
  }

  // Future<void> requestPermissions() async {
  //   await [Permission.storage].request();
  // }

  Future<void> fetchFiles() async {
    try {
      setState(() {
        isLoading = true;
      });

      ListResult result = await storage.ref('uploads/').listAll();

      setState(() {
        uploadedFiles.clear();
        for (Reference ref in result.items) {
          String fileName = ref.name;
          uploadedFiles.add(fileName);
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching files: $e');
    }
  }

  Future<void> uploadFile() async {
    await pickImage();

    if (selectedFile != null) {
      String fileName = DateTime.now().toIso8601String();
      Reference storageReference = storage.ref().child('uploads/$fileName');
      UploadTask uploadTask = storageReference.putFile(selectedFile!);
      await uploadTask.whenComplete(() async {
        fileUrl = await storageReference.getDownloadURL();
        print('File uploaded, download URL: $fileUrl');
      });
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> sendMessage() async {
    final message = messageController.text;
    final title = titleController.text; // Capture the title input

    if ((message.isNotEmpty || fileUrl.isNotEmpty) && title.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('stories').add({
          'title': title, // Upload the title
          'text': message.isNotEmpty ? message : null,
          'file': fileUrl.isNotEmpty ? fileUrl : null,
          'fileType': 'image',
          'timestamp': FieldValue.serverTimestamp(),
        });

        messageController.clear();
        titleController.clear(); // Clear the title input
        setState(() {
          fileUrl = '';
          selectedFile = null;
        });
      } catch (e) {
        print('Error sending message: $e');
      }
    } else {
      print('Title is required, and either message or file must be present');
    }
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Unknown Date';
    }
    DateTime dateTime = timestamp.toDate();
    DateTime now = DateTime.now();

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Today';
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showAddStoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Add New Story', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Caption', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    if (selectedFile != null) ...[
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(selectedFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              setModalState(() {
                                selectedFile = null;
                              });
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Image'),
                      onPressed: () async {
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setModalState(() {
                            selectedFile = File(pickedFile.path);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: isLoading ? null : () async {
                        setModalState(() => isLoading = true);
                        if (selectedFile != null) {
                          String fileName = DateTime.now().toIso8601String();
                          Reference storageReference = storage.ref().child('uploads/$fileName');
                          UploadTask uploadTask = storageReference.putFile(selectedFile!);
                          await uploadTask.whenComplete(() async {
                            fileUrl = await storageReference.getDownloadURL();
                          });
                        }
                        
                        final message = messageController.text;
                        final title = titleController.text;

                        if ((message.isNotEmpty || fileUrl.isNotEmpty) && title.isNotEmpty) {
                          try {
                            await FirebaseFirestore.instance.collection('stories').add({
                              'title': title,
                              'text': message.isNotEmpty ? message : null,
                              'file': fileUrl.isNotEmpty ? fileUrl : null,
                              'fileType': 'image',
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            messageController.clear();
                            titleController.clear();
                            setState(() {
                              fileUrl = '';
                              selectedFile = null;
                            });
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            print('Error sending message: $e');
                          }
                        }
                        setModalState(() => isLoading = false);
                      },
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Add Story', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Top Stories',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: widget.isAdmin ? [
          TextButton.icon(
            onPressed: _showAddStoryBottomSheet,
            icon: const Icon(Icons.add, color: Colors.blue),
            label: const Text('Add', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          )
        ] : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stories')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet'),
                  );
                }

                final docs = snapshot.data?.docs;
                if (docs == null) return const SizedBox.shrink();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    String image = data['file'] ?? '';
                    String text = data['text'] ?? '';
                    String title = data['title'] ?? 'Top Story'; 
                    final timestamp = data['timestamp'] as Timestamp?;
                    String formattedDate = formatDate(timestamp);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (Avatar + Title)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color.fromARGB(255, 255, 180, 68),
                                  child: Icon(Icons.article, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                ],
                              ),
                            ),
                          // Image
                          if (image.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FullScreenImage(imageUrl: image),
                                  ),
                                );
                              },
                              child: Image.network(
                                image,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 250,
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Image unavailable', style: TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                          // Description & Date
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (text.isNotEmpty)
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Colors.black, fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: '$title ',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: text),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Container(
          //   padding: const EdgeInsets.all(15.0),
          //   child: Column(
          //     children: [
          //       TextFormField(
          //         controller: titleController,
          //         decoration: const InputDecoration(
          //           labelText: 'Enter Title',
          //           border: OutlineInputBorder(),
          //         ),
          //       ),
          //       const SizedBox(height: 10),
          //       Row(
          //         children: [
          //           if (selectedFile != null)
          //             Stack(
          //               children: [
          //                 Container(
          //                   width: 50,
          //                   height: 50,
          //                   decoration: BoxDecoration(
          //                     borderRadius: BorderRadius.circular(8),
          //                     image: DecorationImage(
          //                       image: FileImage(selectedFile!),
          //                       fit: BoxFit.cover,
          //                     ),
          //                   ),
          //                   margin: const EdgeInsets.only(right: 8),
          //                 ),
          //                 Positioned(
          //                   top: 0,
          //                   right: -5,
          //                   child: IconButton(
          //                     icon: const Icon(Icons.close, color: Colors.redAccent),
          //                     onPressed: () {
          //                       setState(() {
          //                         selectedFile = null;
          //                       });
          //                     },
          //                   ),
          //                 ),
          //               ],
          //             ),
                  //   Expanded(
                  //     child: TextFormField(
                  //       controller: messageController,
                  //       decoration: const InputDecoration(
                  //         labelText: 'Enter your message',
                  //         border: OutlineInputBorder(),
                  //       ),
                  //     ),
                  //   ),
                  //   IconButton(
                  //     onPressed: uploadFile,
                  //     icon: const Icon(Icons.attach_file),
                  //   ),
                  //   IconButton(
                  //     onPressed: sendMessage,
                  //     icon: const Icon(Icons.send),
                  //   ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
