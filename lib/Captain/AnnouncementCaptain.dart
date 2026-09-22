import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class CaptainViewMessageScreen extends StatefulWidget {
  const CaptainViewMessageScreen({Key? key}) : super(key: key);

  @override
  _CaptainViewMessageScreenState createState() => _CaptainViewMessageScreenState();
}

class _CaptainViewMessageScreenState extends State<CaptainViewMessageScreen> {
  FirebaseStorage storage = FirebaseStorage.instance;
  List<String> uploadedFiles = [];
  bool isLoading = false;
  final picker = ImagePicker();
  File? selectedFile;
  String fileUrl = '';
  final messageController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Text(
          'Announcements',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
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
                Map<String, List<DocumentSnapshot>> groupedMessages = {};

                for (DocumentSnapshot doc in docs!) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp?;

                  if (timestamp == null) {
                    continue;
                  }

                  String formattedDate = formatDate(timestamp);

                  if (!groupedMessages.containsKey(formattedDate)) {
                    groupedMessages[formattedDate] = [];
                  }

                  groupedMessages[formattedDate]!.add(doc);
                }

                List<Widget> messageWidgets = [];
                groupedMessages.forEach((date, messages) {
                  messageWidgets.add(
                    Column(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              date,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot doc = messages[index];
                            final data = doc.data() as Map<String, dynamic>;
                            String file = data['file'] ?? '';
                            String text = data['text'] ?? '';

                            return Card(
                              elevation: 3,
                              color: Colors.grey[200],
                              child: ListTile(
                                contentPadding: file.isNotEmpty
                                    ? const EdgeInsets.all(0)
                                    : const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                title: file.isNotEmpty
                                    ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                             child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          FullScreenImage(imageUrl: file),
                                                    ),
                                                  );
                                                },
                                                child: Image.network(
                                                  file,
                                                  width: double.infinity,
                                                  fit: BoxFit.contain,
                                                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                                    if (loadingProgress == null) {
                                                      return child; // The image is loaded
                                                    } else {
                                                      return Container(
                                                        height: 200, // Set a fixed height for the loader
                                                        child: const Center(
                                                          child: CircularProgressIndicator(), // Simple loader
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                                    // Fallback in case the image fails to load
                                                    return Container(
                                                      height: 200, // Maintain the same height for consistency
                                                      color: Colors.grey[200], // Placeholder background color
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                          size: 80,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                    )
                                    : null,
                                subtitle: text.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Text(text),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                });

                return ListView(
                  children: messageWidgets,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  // Method to share the image using a URL launcher
  /*
  Future<void> _shareImage(BuildContext context) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/?text=$imageUrl');

    if (await canLaunch(whatsappUri.toString())) {
      await launch(whatsappUri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch WhatsApp.'),
        ),
      );
    }
  }
*/


  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Colors.black,
      appBar: AppBar(
       backgroundColor:  Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        /*
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Call the share method when the share icon is pressed
              _shareImage(context);
            },
          ),
        ],
        */
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, // Allow panning (dragging)
          minScale: 0.5,    // Minimum zoom out scale
          maxScale: 4.0,    // Maximum zoom in scale
          child: Image.network(imageUrl), // Display the image
        ),
      ),
    );
  }

  
}
