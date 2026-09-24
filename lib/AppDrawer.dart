import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rolebase/Captains.dart';
import 'package:rolebase/Developers.dart';
import 'package:rolebase/EmergencyContact.dart';
import 'package:rolebase/LoginPage.dart';
import 'package:rolebase/Photos.dart';
import 'package:rolebase/aboutleague.dart';
import 'package:rolebase/grievance_center.dart';
import 'package:rolebase/stories.dart';
import 'package:url_launcher/url_launcher.dart';

const _drawerInk = Color(0xFF12233F);
const _drawerPage = Color(0xFFF5F8FF);
const _drawerBlue = Color(0xFF2864A7);

/// Shared by nested dashboard scaffolds and the home scaffold so the navigation
/// bar always follows the visible drawer.
final ValueNotifier<bool> appDrawerIsOpen = ValueNotifier(false);

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.isAdmin,
    this.showBottomNavigationBar = false,
  });

  final bool isAdmin;
  // Retained for compatibility with existing dashboard callers. The parent
  // home screen decides whether the bottom navigation is visible.
  final bool showBottomNavigationBar;

  Future<void> _openPdfInBrowser(String url) async {
    final pdfUri = Uri.parse(url);
    if (!await launchUrl(pdfUri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open the rulebook');
    }
  }

  Future<String?> _fetchPdfLink() async {
    try {
      final document = await FirebaseFirestore.instance.collection('Rulebook').doc('PDF').get();
      if (document.exists) return document.data()?['link'] as String?;
    } catch (_) {
      // A helpful message is shown at the call site.
    }
    return null;
  }

  Future<void> _logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Future<void> Function() onTap, {
    bool isSelected = false,
    bool isDestructive = false,
  }) {
    final foreground = isDestructive
        ? const Color(0xFFB42318)
        : isSelected
            ? Colors.white
            : _drawerInk;
    final background = isDestructive
        ? const Color(0xFFFFF1F0)
        : isSelected
            ? _drawerBlue
            : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () async {
            if (!isDestructive) Navigator.of(context).pop();
            await onTap();
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: isSelected || isDestructive ? null : Border.all(color: const Color(0xFFDCE3F0)),
            ),
            child: Row(
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                if (isSelected) const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 7),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF667993), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _drawerPage,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(32)),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Container(
                height: 144,
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
                      right: -13,
                      top: -30,
                      child: Icon(Icons.sports_soccer_rounded, size: 160, color: Color(0x33728EC5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFC8DCF9)),
                            ),
                            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hostel League', style: TextStyle(color: _drawerInk, fontSize: 19, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text(
                                  isAdmin ? 'Management dashboard' : 'Captain dashboard',
                                  style: const TextStyle(color: Color(0xFF3B5474), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 10),
              children: [
                _sectionLabel('NAVIGATION'),
                _drawerItem(context, Icons.home_rounded, 'Dashboard', () async {}, isSelected: true),
                _drawerItem(context, Icons.menu_book_outlined, 'Rulebook', () async {
                  final pdfLink = await _fetchPdfLink();
                  if (pdfLink == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load the rulebook.')));
                    }
                    return;
                  }
                  try {
                    await _openPdfInBrowser(pdfLink);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open the rulebook.')));
                    }
                  }
                }),
                _drawerItem(context, Icons.auto_stories_outlined, 'Top Stories', () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TopStories(isAdmin: isAdmin)));
                }),
                _drawerItem(context, Icons.emoji_events_outlined, 'About League', () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const About()));
                }),
                _sectionLabel('PEOPLE AND SUPPORT'),
                _drawerItem(context, Icons.groups_outlined, 'Captains', () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CaptainScreen(isAdmin: isAdmin)));
                }),
                _drawerItem(context, Icons.contact_phone_outlined, 'Emergency Contacts', () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmergencyContactScreen()));
                }),
                _drawerItem(context, Icons.terminal_rounded, 'Developers', () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DevelopersScreen()));
                }),
                _drawerItem(context, Icons.rate_review_outlined, 'Grievance', () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GrievanceCenter(isAdmin: isAdmin)));
                }),
                _drawerItem(context, Icons.photo_library_outlined, 'Photos', () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GalleryScreen()));
                }),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: Color(0xFFDCE3F0)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _drawerItem(context, Icons.logout_rounded, 'Log out', () async {
              try {
                await _logOut(context);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to log out. Please try again.')),
                  );
                }
              }
            }, isDestructive: true),
          ),
        ],
      ),
    );
  }
}
