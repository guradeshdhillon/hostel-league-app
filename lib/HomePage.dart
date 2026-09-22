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
  final String role;  // This will be passed from the LoginPage after login

  HomePage({required this.role});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;  // Track the selected tab index

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
      _selectedIndex = 0;  // Reset index if out of range
    }


    return Scaffold(
      extendBody: true, // Allows the body to flow underneath the floating nav bar
      onDrawerChanged: (isOpen) {
        appDrawerIsOpen.value = isOpen;
      },
      drawer: AppDrawer(
        isAdmin: widget.role == 'management',
      ),
      backgroundColor: const Color(0xFF1E1E1E), // Optional: sleek dark background if applicable
      body: Center(
        // Display the appropriate page based on selected index
        child: currentPages[_selectedIndex],
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: appDrawerIsOpen,
        builder: (context, isDrawerOpen, child) {
          if (isDrawerOpen) return const SizedBox.shrink();

          return SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black, // Solid black background as requested
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(bottomNavItems.length, (index) {
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent, // Solid white background for active
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    (bottomNavItems[index] as Icon).icon,
                    color: isSelected ? Colors.black : Colors.white70, // Icon must be black when on white background
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ),
          );
        },
      ),
    );
  }
}
