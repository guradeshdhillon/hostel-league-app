import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';


class SendMessageScreen extends StatefulWidget {
  const SendMessageScreen({Key? key}) : super(key: key);

  @override
  _SendMessageScreenState createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  FirebaseStorage storage = FirebaseStorage.instance;
  List<String> uploadedFiles = [];
  bool isLoading = false;
  final picker = ImagePicker();
  File? selectedFile;
  String fileUrl = '';
  final messageController = TextEditingController();


  @override
  void initState() {
    super.initState();
    fetchFiles();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    await [Permission.storage].request();
  }

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

    if (message.isNotEmpty || fileUrl.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('announcements').add({
          'text': message.isNotEmpty ? message : null,
          'file': fileUrl.isNotEmpty ? fileUrl : null,
          'fileType': 'image',
          'timestamp': FieldValue.serverTimestamp(),
        });

        messageController.clear();
        setState(() {
          fileUrl = '';
          selectedFile = null;
        });
      } catch (e) {
        print('Error sending message: $e');
      }
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
                                        padding: const EdgeInsets.all(10.0),
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
          Container(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                selectedFile != null
                    ? Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(selectedFile!),
                                fit: BoxFit.cover,
                              ),
                            ),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                          Positioned(
                            top: 0,
                            right: -5,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  selectedFile = null;
                                });
                              },
                            ),
                          )
                        ],
                      )
                    : Container(),
                Expanded(
                  child: TextFormField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: uploadFile,
                  icon: const Icon(Icons.attach_file),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
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

  // Method to open the image URL in the browser
  /*
  Future<void> _openInBrowser(BuildContext context, String imageUrl) async {
    final Uri imageUri = Uri.parse(imageUrl);
    // print('Image URL: $imageUrl');

    if (await canLaunchUrl(imageUri)) {
      await launchUrl(imageUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the browser.'),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        /*
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              _openInBrowser(context, imageUrl);
            },
          ),
        ],
        */
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(imageUrl),  // Display the image from the URL
        ),
      ),
    );
  }
}
