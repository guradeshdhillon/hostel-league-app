import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rolebase/aboutleague.dart';
import 'package:rolebase/Scoreboard.dart'; 
import 'package:rolebase/AnnaWarriorsScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'BlackEaglesScreen.dart';
import 'DefendingTitansScreen.dart';
import 'RetroRivalsScreen.dart';
import 'RisingGiantsScreen.dart';
import 'TheScoutRegimentScreen.dart';
import 'WhiteWalkersScreen.dart';
import 'management_info_screen.dart';
import 'EmergencyContact.dart';
import 'Captains.dart';
import 'Developers.dart';
import 'LoginPage.dart';
import 'Grivance.dart';
import 'stories.dart';
import 'package:rolebase/Photos.dart';

class ManagementLandingPage extends StatefulWidget {
  @override
  _ManagementLandingPageState createState() => _ManagementLandingPageState();
}

class _ManagementLandingPageState extends State<ManagementLandingPage> {
  int _currentIndex = 0;
  late PageController _pageController;
  late Timer _timer;

  final List<Map<String, String>> cardData = [
    {'title': 'Anna Warriors', 'logo': 'assets/logo2.png'},
    {'title': 'Defending Titans', 'logo': 'assets/logo3.png'},
    {'title': 'White Walkers', 'logo': 'assets/logo4.png'},
    {'title': 'The Scout Regiment', 'logo': 'assets/logo5.png'},
    {'title': 'Black Eagles', 'logo': 'assets/logo1.png'},
    {'title': 'Retro Rivals', 'logo': 'assets/logo6.png'},
    {'title': 'Rising Giants', 'logo': 'assets/logo7.png'},
    {'title': 'Management Team', 'logo': 'assets/Management.png'},
  ];


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoSlide();
    

  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_currentIndex < 6) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      _pageController.animateToPage(
        _currentIndex,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Color _teamColor(String title) {
    switch (title) {
      case 'Black Eagles':
        return const Color(0xFF171717);
      case 'Anna Warriors':
        return const Color(0xFFE81D3F);
      case 'Defending Titans':
        return const Color(0xFF163574);
      case 'White Walkers':
        return const Color(0xFF073D37);
      case 'The Scout Regiment':
        return const Color(0xFF278F9B);
      case 'Retro Rivals':
        return const Color(0xFF3D2455);
      case 'Rising Giants':
        return const Color(0xFFF47E2D);
      case 'Management Team':
        return const Color(0xFFBE185D);
      default:
        return Colors.black87;
    }
  }

  Future<void> openPDFInBrowser(String url) async {
    final Uri pdfUri = Uri.parse(url);  // Convert URL to Uri object

    // Open the link in an external browser (e.g., Chrome)
    if (!await launchUrl(pdfUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open the PDF';
    }
  }

  Future<String?> fetchPDFLink() async {
  try {
    // Fetch the document from Firestore
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('Rulebook')  // Replace with your collection name
        .doc('PDF')      // Replace with your document ID
        .get();

    // Check if the document exists
    if (documentSnapshot.exists) {
      // Extract the 'link' field from the document
      String pdfLink = documentSnapshot['link'];  // Assuming the field is named 'link'
      return pdfLink;  // Return the PDF link
    } else {
      print('Document does not exist');
    }
  } catch (e) {
    print('Error fetching document: $e');
  }
  
  return null;  // Return null if there's an error or the document doesn't exist
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Cream background to match image
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Row(
          children: [
            const Text(
              'Hostel league',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScoreboardScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black87, width: 1.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.leaderboard_rounded, color: Colors.black87, size: 22),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: Column(
        children: [
            // Fixed hero photo directly below the dashboard header.
            AspectRatio(
            aspectRatio: 1448 / 655,
              child: ClipRect(
                child: Transform.scale(
                  scale: 1.08,
                  child: Image.asset(
                    'managmentgrp.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
            ),

            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
                    child: GridView.builder(
                  shrinkWrap: true, 
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 2.42,
                  ),
                  itemCount: cardData.length,
                  itemBuilder: (context, index) {
                    final logoSize = cardData[index]['title'] == 'Black Eagles'
                        ? 68.0
                        : 76.0;
                    return GestureDetector(
                      onTap: () {
                        switch (cardData[index]['title']) {
                          case 'Black Eagles':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BlackEaglesScreen()),
                            );
                            break;
                          case 'Anna Warriors':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AnnaWarriorsScreen()),
                            );
                            break;
                          case 'Defending Titans':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DefendingTitansScreen()),
                            );
                            break;
                          case 'White Walkers':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => WhiteWalkersScreen()),
                            );
                            break;
                          case 'The Scout Regiment':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TheScoutRegimentScreen()),
                            );
                            break;
                          case 'Retro Rivals':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RetroRivalsScreen()),
                            );
                            break;
                          case 'Rising Giants':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RisingGiantsScreen()),
                            );
                            break;
                          case 'Management Team':
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ManagementInfoScreen()),
                            );
                            break;
                          default:
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CardScreen(cardData[index]['title'] ?? 'Unknown Card')),
                            );      
                            break;
                        }
                      },
                    child: Card(
                      color: _teamColor(cardData[index]['title'] ?? ''),
                      elevation: 9,
                      shadowColor: Colors.black.withOpacity(0.55),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Align(
                        alignment: index.isEven
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: logoSize,
                                height: logoSize,
                                child: Image.asset(
                                  cardData[index]['logo'] ?? 'assets/default_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image_not_supported);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  // Helper function to create beautifully styled drawer items
  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Function onTap, {bool isSelected = false, bool isDestructive = false}) {
    final textColor = isDestructive ? const Color(0xFFD32F2F) : (isSelected ? Colors.white : Colors.black87);
    final iconColor = isDestructive ? const Color(0xFFD32F2F) : (isSelected ? Colors.white : Colors.black54);
    final bgColor = isSelected ? const Color(0xFF2B2826) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: bgColor,
        leading: Icon(icon, color: iconColor, size: 26),
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16)),
        onTap: () => onTap(),
      ),
    );
  }
}

class CardScreen extends StatelessWidget {
  final String title;
  CardScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       backgroundColor:  const Color.fromARGB(255, 255, 180, 68),
        title: Text(title),
      ),
      body: Center(
        child: Text('Details for $title will be shown here'),
      ),
    );
  }
}
