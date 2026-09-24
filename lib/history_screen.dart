import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:rolebase/match_fixture_card.dart';



class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {


  final _formKey = GlobalKey<FormState>();
  final _matchNumberController = TextEditingController();
  String? _team1Name;
  String? _team2Name;
  String? _games;
  String? _matchType;
  DateTime _selectedDate = DateTime.now();
  String? _wonBy;
  int? _points;
  String? _name;
  XFile? _imageFile;

  final List<String> _teams = [
    'Black Eagles',
    'Anna Warriors',
    'Defending Titans',
    'White Walkers',
    'The Scout Regiment',
    'Retro Rivals',
    'Rising Giants',
  ];

  final List<String> _gamesdropdown = [
    'Cricket',
    'Football',
    'Volleyball',
    'Basketball',
    'Badminton',
    'Tabel Tennis',
    'Tug of War',
    'Valorant',
  ];

  final List<String> _matchTypeDropdown = [
    'League Match',
    'Semifinal',
    'Final',
  ];

  final List<int> _pointsOptions = [0, 2, 3, 5];

  final List<String> _nameDropdown = [
    'Uday Rudrakar',
    'Kushal Khadgi',
    'Nakul Wanjari',
    'Kevin Beji',
    'Steavo Babu',
    'Atharva Men',
    'Omkar Gangamwar',
    'Om Gawande',
    'Gaurav Pididkar'
  ];

  bool _isUploading = false; 
  String? _uploadedImageUrl;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _imageFile = image;
        });
        await _uploadImage();
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    setState(() {
      _isUploading = true; // Show loader
    });

    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = imageRef.putFile(File(_imageFile!.path));

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false; // Hide loader
        _uploadedImageUrl = downloadUrl; // Store the uploaded image URL
      });

      return downloadUrl;
    } catch (e) {
      print('Error during image upload: $e');
      setState(() {
        _isUploading = false; // Hide loader in case of an error
      });
      return null;
    }
  }

  Future<void> _addHistory() async {
  // Ensure the form is valid before proceeding
  if (_formKey.currentState?.validate() ?? false) {
    try {
      setState(() {
        _isSubmitting = true; // Start the loading indicator
      });

      // Upload the image first
      final imageUrl = await _uploadImage();
      if (imageUrl == null) {
        setState(() {
          _isSubmitting = false; // Stop the loading indicator
        });

        // Show error snackbar if image upload fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Submit form data to Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('history').add({
        'match_number': _matchNumberController.text,
        'team1_name': _team1Name,
        'team2_name': _team2Name,
        'date': _selectedDate.toIso8601String(),
        'won_by': _wonBy,
        'points': _points,
        'image_url': imageUrl,
        'sports': _games,
        'match_type': _matchType,
        'name': _name,
      });

      updateScores(_wonBy, _points); //For score board update

      // Clear form fields
      _matchNumberController.clear();
      _team1Name = null;
      _team2Name = null;
      _wonBy = null;
      _points = null;
      _name = null;
      _uploadedImageUrl = null; // Reset the image URL
      _games = null;
      _matchType = null;
      _selectedDate = DateTime.now();

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('History added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Close the modal after submission
      Navigator.of(context).pop();
    } catch (error) {
      // Handle submission errors and display a relevant message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Stop loading indicator after the process
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

  void _showAddHistoryForm() {
    _matchNumberController.clear();
    _team1Name = null;
    _team2Name = null;
    _wonBy = null;
    _points = null;
    _name = null;
    _uploadedImageUrl = null; // Reset the image URL
    _games = null;
    _matchType = null;
    _selectedDate = DateTime.now();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.75,  // Ensuring the form takes up 75% of the screen height
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text('Add History'),
            toolbarHeight: kToolbarHeight,
             backgroundColor:  const Color.fromARGB(255, 255, 180, 68),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _matchNumberController,
                              decoration: InputDecoration(
                                labelText: 'Match Number',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.numbers),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter match number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            _buildDropdown<String>(
                              label: 'Select Team 1',
                              value: _team1Name,
                              onChanged: (value) {
                                setState(() {
                                  _team1Name = value;
                                  if (_team2Name == _team1Name) {
                                    _team2Name = null;
                                  }
                                  _wonBy = null; // Reset the "Won By" field when team 1 is changed
                                });
                              },
                              items: _teams,
                              hintText: 'Select Team 1',
                            ),
                            SizedBox(height: 16),
                            _buildDropdown<String>(
                              label: 'Select Team 2',
                              value: _team2Name,
                              onChanged: (value) {
                                setState(() {
                                  _team2Name = value;
                                  _wonBy = null; // Reset the "Won By" field when team 2 is changed
                                });
                              },
                              items: _teams.where((team) => team != _team1Name).toList(),
                              hintText: 'Select Team 2',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDropdown<String>(
                              label: 'Sports',
                              value: _games,
                              onChanged: (value) {
                                setState(() {
                                  _games = value;
                                });
                              },
                              items: _gamesdropdown,
                              hintText: 'Select Sports',
                            ),
                            SizedBox(height: 16),
                            _buildDropdown<String>(
                              label: 'Match Type',
                              value: _matchType,
                              onChanged: (value) {
                                setState(() {
                                  _matchType = value;
                                });
                              },
                              items: _matchTypeDropdown,
                              hintText: 'Select Match Type',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                            SizedBox(height: 16),
                            _buildDropdown<String>(
                              label: 'Won By',
                              value: _wonBy,
                              onChanged: (value) {
                                setState(() {
                                  _wonBy = value;
                                });
                              },
                              items: _teams,
                              hintText: 'Select the winner',
                            ),
                            SizedBox(height: 16),
                            _buildDropdown<int>(
                              label: 'Points',
                              value: _points,
                              onChanged: (value) {
                                setState(() {
                                  _points = value;
                                });
                              },
                              items: _pointsOptions,
                              hintText: 'Points',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 16),
                            _buildDropdown<String>(
                              label: 'Name',
                              value: _name,
                              onChanged: (value) {
                                setState(() {
                                  _name = value;
                                });
                              },
                              items: _nameDropdown,
                              hintText: 'Enter your Name.',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _isUploading
                                  ? Center(child: CircularProgressIndicator())
                                  : _uploadedImageUrl == null
                                      ? const Text('No image selected')
                                      : Image.network(
                                            _uploadedImageUrl!, // Show uploaded image
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ), // Display the uploaded image after success
                              const SizedBox(height: 16), // Add space between image and button
                              TextButton.icon(
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Upload Image'),
                                onPressed: _isUploading ? null : _pickImage,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the modal form
                        },
                        child: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey, // Grey for cancel button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null // Disable the button while submitting
                          : () {
                              if (_validateForm()) {
                                _addHistory(); 
                              }
                            },
                      child: _isSubmitting 
                          ? CircularProgressIndicator( // Show loader when submitting
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 180, 68),
                        alignment: Alignment.center,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}


void updateScores(String? wonBy, int? points) async {
  if (wonBy == null || points == null) {
    // Handle error: either wonBy or points are null
    return;
  }

  // Get a reference to the Firestore collection
  CollectionReference teamsCollection = FirebaseFirestore.instance.collection('teams');

  try {
    // Get the document reference for the winning team
    DocumentReference teamDoc = teamsCollection.doc(wonBy);

    // Update the score field
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(teamDoc);

      if (!snapshot.exists) {
        throw Exception("Team does not exist");
      }

      // Calculate new score
      int currentScore = snapshot.get('score') ?? 0;
      int newScore = currentScore + points;

      // Update the score in Firestore
      transaction.update(teamDoc, {'score': newScore});
    });

    print('Score updated successfully');
  } catch (e) {
    print('Error updating score: $e');
  }
}



  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false; // Form is not valid
    }

    if (_team1Name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select Team 1')),
      );
      return false;
    }

    if (_team2Name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select Team 2')),
      );
      return false;
    }

    if (_games == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select Sports')),
      );
      return false;
    }

    if (_matchType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select Match Type')),
      );
      return false;
    }

    if (_team2Name == _team1Name) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Both team cannot be Same')),
      );
      return false;
    }

    if (_wonBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select who won')),
      );
      return false;
    }

    if (_points == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select points')),
      );
      return false;
    }

    if (_name == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please Enter your Name')),
      );
      return false;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload an image')),
      );
      return false;
    }

    if (_wonBy != _team1Name && _wonBy != _team2Name) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Who Won the Match Man?')),
      );
      return false;
    }

    return true; // All validations passed
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required void Function(T?) onChanged,
    required List<T> items,
    String? hintText,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hintText ?? label),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Text(
          'Match History',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF12233F),
            letterSpacing: -0.5,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('history')
          .orderBy('date', descending: true) // Order by date, most recent first
          .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2864A7)));
          }

          final historyDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: historyDocs.length,
            itemBuilder: (context, index) {
              final doc = historyDocs[index].data() as Map<String, dynamic>?;

              if (doc == null) {
                return ListTile(
                  title: Text('Error: Document is null'),
                );
              }

        // Extract initials for team names
            String getInitials(String teamName) {
              List<String> names = teamName.split(' ');
              String initials = '';
                for (var name in names) {
                  if (name.isNotEmpty) {
                    initials += name[0];
                  }
                }
              return initials.toUpperCase();
            }

            String team1Initials = getInitials(doc['team1_name'] ?? 'Unknown');
              String team2Initials = getInitials(doc['team2_name'] ?? 'Unknown');
              String wonBy = doc['won_by'] ?? 'Unknown';
              String wonByInitials = wonBy.isNotEmpty ? getInitials(wonBy) : '';

              DateTime date = DateTime.parse(doc['date']);
              DateTime now = DateTime.now();

              // Get the formatted date header based on the date
              String getDateHeader(DateTime date) {
                if (date.day == now.day &&
                    date.month == now.month &&
                    date.year == now.year) {
                  return 'Today';
                } else if (date.day == now.subtract(Duration(days: 1)).day &&
                    date.month == now.month &&
                    date.year == now.year) {
                  return 'Yesterday';
                } else {
                  return DateFormat('dd MMMM yyyy').format(date);
                }
              }

              String formattedDate = DateFormat('yyyy-MM-dd').format(date);
              String formattedTime = DateFormat('HH:mm').format(date);

              // Show the date header if it's the first entry or the date has changed from the previous match
              bool shouldShowDateHeader = index == 0 ||
                  getDateHeader(DateTime.parse(historyDocs[index - 1]['date'])) !=
                      getDateHeader(date);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shouldShowDateHeader)
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC8DCF9)),
                        ),
                        child: Text(
                          getDateHeader(date),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2864A7),
                          ),
                          textAlign: TextAlign.center, // Ensure the text is centered
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: MatchFixtureCard(
                      match: doc,
                      dateLabel: '$formattedDate · $formattedTime',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MatchDetailScreen(matchData: doc),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHistoryForm,
        tooltip: 'Add History',
        child: Icon(Icons.add),
        backgroundColor:  const Color.fromARGB(255, 255, 180, 68),
      ),
    );
  }
}




class MatchDetailScreen extends StatelessWidget {
  final Map<String, dynamic> matchData;

  MatchDetailScreen({required this.matchData});

  @override
  Widget build(BuildContext context) {
  DateTime date = DateTime.parse(matchData['date']);
  String formattedDate = DateFormat('yyyy-MM-dd').format(date);
  String formattedTime = DateFormat('HH:mm').format(date);

  // Function to get initials of the team name
  String getInitials(String name) {
  List<String> words = name.split(' ');
  String initials = '';
  for (var word in words) {
    if (word.isNotEmpty) {
      initials += word[0]; // Get the first character of each word
    }
  }
  return initials.toUpperCase(); // Convert initials to uppercase
}




  return Scaffold(
    appBar: AppBar(
      title: Text('Match Details'),
          backgroundColor:  const Color.fromARGB(255, 255, 180, 68),
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          _buildInfoSection(
              'Match Number', matchData['match_number'].toString(), Icons.numbers),
          _buildInfoSection(
  'Teams',
  '${getInitials(matchData['team1_name'])} vs ${getInitials(matchData['team2_name'])}', 
  Icons.sports_esports,
),

          _buildInfoSection('Date', formattedDate, Icons.date_range),
          _buildInfoSection('Time', formattedTime, Icons.access_time),
          _buildInfoSection('Sports', matchData['sports'], Icons.sports),
          _buildInfoSection('Match Type', matchData['match_type'], Icons.category),
          _buildInfoSection('Points', matchData['points'].toString(), Icons.star),
          _buildInfoSection('Won By', matchData['won_by'], Icons.emoji_events),
          if (matchData['image_url'] != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(imageUrl: matchData['image_url']!), // Pass the image URL
                  ),
                );
              },
              child: _buildImageSection(matchData['image_url']!),
            ),

          SizedBox(height: 16), // Adds space at the bottom for padding
        ],
      ),
    ),
  );
}




  // Build Header Section with Match Summary
  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
         Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display team initials instead of full team names
              Text(
                '${extractInitials(matchData['team1_name'])} vs ${extractInitials(matchData['team2_name'])}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              Icon(
                Icons.sports_soccer,
                color: Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }
  String extractInitials(String teamName) {
  return teamName
      .split(' ')
      .map((word) => word.isNotEmpty ? word[0] : '')
      .join()
      .toUpperCase();
}

  // Build Info Section with Icon and Content
  Widget _buildInfoSection(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[700]),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey[400],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build Image Section with rounded image display
  Widget _buildImageSection(String imageUrl) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child; // Image is fully loaded, return the image widget.
          } else {
            // While the image is loading, show a CircularProgressIndicator.
            return Container(
              height: 200, // Set a fixed height for the loader placeholder
              child: Center(
                child: CircularProgressIndicator(), // Simple indeterminate loader
              ),
            );
          }
        },
      ),
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
        backgroundColor: Colors.transparent,
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


