import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';

class CaptainScreen extends StatelessWidget {
  final bool isAdmin;
  const CaptainScreen({Key? key, this.isAdmin = false}) : super(key: key);

  // Method to launch the dialer
  void _launchDialer(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  Future<void> _uploadExcel(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        var file = result.files.single.path!;
        var bytes = File(file).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        // Use the first sheet or 'Sheet1'
        var sheetName = excel.tables.keys.first;
        var table = excel.tables[sheetName];
        
        if (table != null && table.rows.length > 1) {
          // Assume row 0 is header. Data starts from row 1.
          final batch = FirebaseFirestore.instance.batch();
          final collection = FirebaseFirestore.instance.collection('captains_contacts');

          for (int i = 1; i < table.rows.length; i++) {
            var row = table.rows[i];
            
            // Expected Format:
            // 0: Team Name
            // 1: Captain Name
            // 2: Captain Phone
            // 3: Vice Captain Name
            // 4: Vice Captain Phone
            
            if (row.length >= 5 && row[0] != null) {
              String teamName = row[0]?.value.toString() ?? '';
              String capName = row[1]?.value.toString() ?? '';
              String capPhone = row[2]?.value.toString() ?? '';
              String vcName = row[3]?.value.toString() ?? '';
              String vcPhone = row[4]?.value.toString() ?? '';
              
              if (teamName.isNotEmpty) {
                var docRef = collection.doc(teamName);
                batch.set(docRef, {
                  'teamName': teamName,
                  'captainName': capName,
                  'captainPhone': capPhone,
                  'viceCaptainName': vcName,
                  'viceCaptainPhone': vcPhone,
                });
              }
            }
          }
          
          await batch.commit();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contacts updated successfully!')),
            );
          }
        }
      }
    } catch (e) {
      print('Error uploading Excel: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating contacts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 180, 68),
        title: const Text('Captains Contact'),
        actions: isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: () => _uploadExcel(context),
                  tooltip: 'Upload Excel Sheet',
                )
              ]
            : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('captains_contacts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading contacts.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No contacts available. Admins can upload an Excel sheet to populate this list.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Column(
                    children: [
                      // Main parent Tile for the team name
                      ListTile(
                        title: Text(
                          data['teamName'] ?? 'Unknown Team',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Divider(height: 1), 
                      ListTile(
                        title: Text(
                          data['captainName'] ?? 'No Captain',
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () {
                            if (data['captainPhone'] != null && data['captainPhone'].toString().isNotEmpty) {
                              _launchDialer(data['captainPhone'].toString());
                            }
                          },
                        ),
                      ),
                      
                      ListTile(
                        title: Text(
                          data['viceCaptainName'] ?? 'No Vice Captain',
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.call),
                          onPressed: () {
                            if (data['viceCaptainPhone'] != null && data['viceCaptainPhone'].toString().isNotEmpty) {
                              _launchDialer(data['viceCaptainPhone'].toString());
                            }
                          },
                        ),
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
