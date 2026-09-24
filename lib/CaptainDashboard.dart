import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rolebase/Scoreboard.dart';
import 'management_info_screen.dart';
import 'package:rolebase/Captain/AnnaWarriorCaptain.dart';
import 'package:rolebase/Captain/BlackEagleCaptain.dart';
import 'package:rolebase/Captain/DefendingTitansCaptain.dart';
import 'package:rolebase/Captain/GrievanceCaptian.dart';
import 'package:rolebase/Captain/RetroRivalCaptain.dart';
import 'package:rolebase/Captain/RisingGiantCaptain.dart';
import 'package:rolebase/Captain/TheScoutRegimentCaptain.dart';
import 'package:rolebase/Captain/WhiteWalkersCaptain.dart';
import 'EmergencyContact.dart';
import 'Captains.dart';
import 'Developers.dart';
import 'LoginPage.dart';
import 'package:rolebase/stories.dart';
import 'package:rolebase/aboutleague.dart';
import 'package:rolebase/Photos.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';
import 'AppDrawer.dart';
import 'team_roster_screen.dart';

class CaptainLandingPage extends StatefulWidget {
  @override
  _CaptainLandingPageState createState() => _CaptainLandingPageState();
}

class _CaptainLandingPageState extends State<CaptainLandingPage> {
  int _currentIndex = 0;
  late PageController _pageController;
  late Timer _timer;

  // Sample list of card data (can be replaced with actual data)
  final List<Map<String, String>> cardData = [
    {'title': 'Anna Warriors', 'logo': 'assets/logo2.png'},
    {'title': 'Defending Titans', 'logo': 'assets/logo3.png'},
    {'title': 'White Walkers', 'logo': 'assets/logo4.png'},
    {'title': 'The Scout Regiment', 'logo': 'assets/logo5.png'},
    {'title': 'Black Eagles', 'logo': 'assets/logo1.png'},
    {'title': 'Retro Rivals', 'logo': 'assets/logo6.png'},
    {'title': 'Rising Giants', 'logo': 'assets/logo7.png'},
    {'title': 'Management Info', 'logo': 'assets/Management.png'},
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
      case 'Management Info':
        return const Color(0xFFBE185D);
      default:
        return Colors.black87;
    }
  }

  Future<void> openPDFInBrowser(String url) async {
    final Uri pdfUri = Uri.parse(url); // Convert URL to Uri object

    // Open the link in an external browser (e.g., Chrome)
    if (!await launchUrl(pdfUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open the PDF link';
    }
  }

  Future<String?> fetchPDFLink() async {
    try {
      // Fetch the document from Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Rulebook') // Replace with your collection name
          .doc('PDF') // Replace with your document ID
          .get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        // Extract the 'link' field from the document
        String pdfLink =
            documentSnapshot['link']; // Assuming the field is named 'link'
        return pdfLink; // Return the PDF link
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching document: $e');
    }

    return null; // Return null if there's an error or the document doesn't exist
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      onDrawerChanged: (isOpen) {
        appDrawerIsOpen.value = isOpen;
      },
      drawer: const AppDrawer(isAdmin: false),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          color: const Color(0xFFF5F8FF),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF12233F)),
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
                    color: Color(0xFF12233F),
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ScoreboardScreen()),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF2864A7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.leaderboard_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Fixed hero photo directly below the dashboard header.
          SizedBox(
            height: 220,
            child: ClipRect(
              child: Image.asset(
                'managmentgrp.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0.10, -1),
              ),
            ),
          ),

          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: Transform.scale(
                    scale: 2.8,
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'managmentgrp.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.15,
                        ),
                        itemCount: cardData.length,
                        itemBuilder: (context, index) {
                          final logoSize =
                              cardData[index]['title'] == 'Black Eagles'
                                  ? 68.0
                                  : 76.0;
                          return GestureDetector(
                            onTap: () {
                              switch (cardData[index]['title']) {
                                case 'Black Eagles':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const TeamRosterScreen(teamName: 'Black Eagles', isAdmin: false)),
                                  );
                                  break;
                                case 'Anna Warriors':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const TeamRosterScreen(teamName: 'Anna Warriors', isAdmin: false)),
                                  );
                                  break;
                                case 'Defending Titans':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const TeamRosterScreen(teamName: 'Defending Titans', isAdmin: false)),
                                  );
                                  break;
                                case 'White Walkers':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const TeamRosterScreen(teamName: 'White Walkers', isAdmin: false)),
                                  );
                                  break;
                                case 'The Scout Regiment':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const TeamRosterScreen(teamName: 'The Scout Regiment', isAdmin: false)),
                                  );
                                  break;
                                case 'Retro Rivals':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const TeamRosterScreen(teamName: 'Retro Rivals', isAdmin: false)),
                                  );
                                  break;
                                case 'Rising Giants':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const TeamRosterScreen(teamName: 'Rising Giants', isAdmin: false)),
                                  );
                                  break;
                                case 'Management Info':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ManagementInfoScreen()),
                                  );
                                  break;
                                default:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CardScreen(
                                            cardData[index]['title'] ??
                                                'Unknown Card')),
                                  );
                                  break;
                              }
                            },
                            child: Card(
                              color: Colors.black,
                              elevation: 7,
                              shadowColor: Colors.black.withOpacity(0.55),
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _teamColor(
                                              cardData[index]['title'] ?? ''),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.18),
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
                                              cardData[index]['logo'] ??
                                                  'assets/default_logo.png',
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(
                                                    Icons.image_not_supported);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to create drawer items
  ListTile _buildDrawerItem(
      BuildContext context, IconData icon, String title, Function onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => onTap(),
    );
  }
}

// Screen that each card will navigate to
class CardScreen extends StatelessWidget {
  final String title;
  CardScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 180, 68),
        title: Text(title),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Center(
        child: Text('Details for $title will be shown here'),
      ),
    );
  }
}
