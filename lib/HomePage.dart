import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rolebase/Captain/AnnouncementCaptain.dart';
import 'package:rolebase/Captain/HistoryCaptain.dart';
import 'package:rolebase/CaptainDashboard.dart';
import 'package:rolebase/announcement.dart';
import 'package:rolebase/history_screen.dart';
import 'package:rolebase/ManagementDashboard.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:rolebase/AppDrawer.dart';

class HomePage extends StatefulWidget {
  final String role; // This will be passed from the LoginPage after login

  HomePage({required this.role});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track the selected tab index

  // Pages for Management
  final List<Widget> _managementPages = [
    ManagementLandingPage(),
    SendMessageScreen(), // Management-specific announcements
    HistoryScreen(), // Shared screen
  ];

  // Pages for Captain
  final List<Widget> _captainPages = [
    CaptainLandingPage(),
    CaptainViewMessageScreen(), // Captain-specific announcements
    HistoryCaptain(), // Shared screen for captains
  ];

  // Handle bottom navigation tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fallback if an unrecognized role is passed
    List<Widget> currentPages;
    List<Widget> bottomNavItems;

    if (widget.role == 'management') {
      currentPages = _managementPages;
      bottomNavItems = [
        Icon(Icons.home, size: 30),
        Icon(Icons.announcement, size: 30),
        Icon(Icons.history, size: 30),
      ];
    } else if (widget.role == 'captain') {
      currentPages = _captainPages;
      bottomNavItems = [
        Icon(Icons.home, size: 30),
        Icon(Icons.announcement, size: 30),
        Icon(Icons.history, size: 30),
      ];
    } else {
      // Handle unknown roles
      currentPages = [Text('Error: Unrecognized role')];
      bottomNavItems = [Icon(Icons.error, size: 30)];
    }

    // Ensure selectedIndex is valid
    if (_selectedIndex >= currentPages.length) {
      _selectedIndex = 0; // Reset index if out of range
    }

    return Scaffold(
      extendBody:
          true, // Allows the body to flow underneath the floating nav bar
      onDrawerChanged: (isOpen) {
        appDrawerIsOpen.value = isOpen;
      },
      drawer: AppDrawer(
        isAdmin: widget.role == 'management',
      ),
      backgroundColor: const Color(0xFFF5F8FF),
      body: Center(
        // Display the appropriate page based on selected index
        child: currentPages[_selectedIndex],
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: appDrawerIsOpen,
        builder: (context, isDrawerOpen, child) {
          // Keep the primary navigation visible for its three tabs, but never
          // while the side drawer is open.
          if (isDrawerOpen) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.paddingOf(context).bottom + 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D3065).withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(bottomNavItems.length, (index) {
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => _onItemTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 5),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2864A7)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Icon(
                      (bottomNavItems[index] as Icon).icon,
                      color: isSelected
                          ? const Color(0xFF2864A7)
                          : const Color(0xFF64738A),
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
