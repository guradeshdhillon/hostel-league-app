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

const _storiesInk = Color(0xFF12233F);
const _storiesPage = Color(0xFFF5F8FF);
const _storiesBlue = Color(0xFF2864A7);

class TopStories extends StatefulWidget {
  final bool isAdmin;
  const TopStories({Key? key, this.isAdmin = false}) : super(key: key);

  @override
  _TopStoriesState createState() => _TopStoriesState();
}

class _StoriesHero extends StatelessWidget {
  const _StoriesHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFDCEBFF), Color(0xFFD8F7EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFC8DCF9)),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -8,
            top: -22,
            child: Icon(Icons.auto_stories_rounded, size: 164, color: Color(0x33728EC5)),
          ),
          const Positioned(
            right: 25,
            bottom: 20,
            child: Icon(Icons.campaign_outlined, size: 38, color: _storiesBlue),
          ),
          Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.76),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LEAGUE UPDATES',
                    style: TextStyle(color: _storiesBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .65),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'What is happening now.',
                  style: TextStyle(color: _storiesInk, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.5),
                ),
                const SizedBox(height: 5),
                const SizedBox(
                  width: 235,
                  child: Text(
                    'Latest announcements, moments and updates from Hostel League.',
                    style: TextStyle(color: Color(0xFF3B5474), fontSize: 13, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      backgroundColor: _storiesPage,
      appBar: AppBar(
        title: const Text(
          'Top Stories',
          style: TextStyle(color: _storiesInk, fontWeight: FontWeight.w900, fontSize: 25),
        ),
        titleSpacing: 16,
        backgroundColor: _storiesPage,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _storiesInk),
        actions: widget.isAdmin ? [
          TextButton.icon(
            onPressed: _showAddStoryBottomSheet,
            icon: const Icon(Icons.add, color: _storiesBlue),
            label: const Text('Add', style: TextStyle(color: _storiesBlue, fontWeight: FontWeight.w800)),
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
                      margin: const EdgeInsets.only(bottom: 14.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDCE3F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x120D3065), blurRadius: 18, offset: Offset(0, 7)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header (Avatar + Title)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFFEAF3FF),
                                  child: Icon(Icons.auto_stories_outlined, color: _storiesBlue, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(color: _storiesInk, fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                ),
                                ],
                              ),
                            ),
                          // Image
                          if (image.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenImage(imageUrl: image),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    image,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: 220,
                                        color: const Color(0xFFEAF3FF),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image_outlined, size: 42, color: Color(0xFF64738A)),
                                            SizedBox(height: 8),
                                            Text('Image unavailable', style: TextStyle(color: Color(0xFF64738A))),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                          // Description & Date
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (text.isNotEmpty)
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(color: Color(0xFF53627A), fontSize: 14, height: 1.4),
                                      children: [
                                        TextSpan(
                                          text: '$title ',
                                          style: const TextStyle(fontWeight: FontWeight.w800),
                                        ),
                                        TextSpan(text: text),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(color: Color(0xFF64738A), fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                              ],
                            ),
                          ),
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
