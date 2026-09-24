import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rolebase/match_fixture_card.dart';



class HistoryCaptain extends StatefulWidget {
  @override
  _HistoryCaptainState createState() => _HistoryCaptainState();
}

class _HistoryCaptainState extends State<HistoryCaptain> {
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
            .orderBy('date', descending: true)
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

              String getInitials(String teamName) {
                List<String> names = teamName.split(' ');
                return names.map((name) => name[0]).join().toUpperCase();
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



