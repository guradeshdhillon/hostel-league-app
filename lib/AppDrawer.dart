import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rolebase/Scoreboard.dart';
import 'package:rolebase/aboutleague.dart';
import 'package:rolebase/EmergencyContact.dart';
import 'package:rolebase/Captains.dart';
import 'package:rolebase/Developers.dart';
import 'package:rolebase/Grivance.dart'; // Management grievance
import 'package:rolebase/Captain/GrievanceCaptian.dart'; // Captain grievance
import 'package:rolebase/stories.dart';
import 'package:rolebase/Photos.dart';
import 'package:rolebase/LoginPage.dart';

/// Shared by nested dashboard scaffolds and the home scaffold so the floating
/// navigation bar always follows the visible drawer.
final ValueNotifier<bool> appDrawerIsOpen = ValueNotifier(false);

class AppDrawer extends StatelessWidget {
  final bool isAdmin;
  // Retained so hot reload can update an already-mounted const drawer.
  // The bottom navigation is now controlled by the parent home screen.
  final bool showBottomNavigationBar;

  const AppDrawer({
    Key? key,
    required this.isAdmin,
    this.showBottomNavigationBar = false,
  }) : super(key: key);

  Future<void> openPDFInBrowser(String url) async {
    final Uri pdfUri = Uri.parse(url);
    if (!await launchUrl(pdfUri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open the PDF';
    }
  }

  Future<String?> fetchPDFLink() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('Rulebook')
          .doc('PDF')
          .get();
      if (documentSnapshot.exists) {
        return documentSnapshot['link'];
      }
    } catch (e) {
      print('Error fetching document: $e');
    }
    return null;
  }

  Future<void> _logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

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
        onTap: () {
          appDrawerIsOpen.value = false;
          onTap();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawerContents = Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.black87, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TNPS League', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)),
                        Text(isAdmin ? '@management' : '@captain', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.black12, height: 1, indent: 24, endIndent: 24),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, Icons.home_rounded, 'Dashboard', () {
                  Navigator.pop(context);
                }, isSelected: true),
                _buildDrawerItem(context, Icons.menu_book, 'RuleBook', () async {
                  String? pdfLink = await fetchPDFLink();
                  if (pdfLink != null) {
                    try {
                      await openPDFInBrowser(pdfLink);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open the PDF in browser')));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load PDF link')));
                  }
                }),
                _buildDrawerItem(context, Icons.memory_outlined, 'Top Stories', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TopStories(isAdmin: isAdmin)));
                }),
                _buildDrawerItem(context, Icons.book_outlined, 'About League', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => About()));
                }),
                _buildDrawerItem(context, Icons.quick_contacts_dialer_rounded, 'Captains', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CaptainScreen(isAdmin: isAdmin)));
                }),
                _buildDrawerItem(context, Icons.call_outlined, 'Emergency Contacts', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EmergencyContactScreen()));
                }),
                _buildDrawerItem(context, Icons.stay_current_portrait_rounded, 'Developers', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DevelopersScreen()));
                }),
                _buildDrawerItem(context, Icons.rate_review_sharp, 'Grievance', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => isAdmin ? ManagementGrievanceScreen() : CaptainGrievanceScreen()));
                }),
                _buildDrawerItem(context, Icons.image_outlined, 'Photos', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => GalleryScreen()));
                }),
              ],
            ),
          ),
          const Divider(color: Colors.black12, height: 1, indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _buildDrawerItem(
              context,
              Icons.logout_rounded,
              'Log out',
              () async {
                try {
                  await _logOut(context);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unable to log out. Please try again.')),
                    );
                  }
                }
              },
              isDestructive: true,
            ),
          ),
        ],
    );

    return Drawer(
      backgroundColor: const Color(0xFFE8ECEF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: drawerContents,
    );
  }
}
