 import 'package:curved_navigation_bar/curved_navigation_bar.dart';
 import 'package:rolebase/announcement.dart';
import 'package:rolebase/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:rolebase/ManagementDashboard.dart';
import 'package:rolebase/AppDrawer.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of widgets for different tabs
  static List<Widget> _pages = <Widget>[
    ManagementLandingPage(),
     SendMessageScreen(),
    HistoryScreen(),
  ];

  // Method to handle bottom navigation bar item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows the body to flow underneath the floating nav bar
      onDrawerChanged: (isOpen) {
        appDrawerIsOpen.value = isOpen;
      },
      drawer: const AppDrawer(isAdmin: true),
      backgroundColor: const Color(0xFF1E1E1E), // Match the sleek dark theme
      body: Center(
        // Display the corresponding page based on the current index
        child: _pages[_selectedIndex],
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
            children: List.generate(3, (index) {
              final isSelected = _selectedIndex == index;
              
              // The 3 icons used for the management home page
              IconData iconData;
              if (index == 0) iconData = Icons.home;
              else if (index == 1) iconData = Icons.announcement;
              else iconData = Icons.history;

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
                    iconData,
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

