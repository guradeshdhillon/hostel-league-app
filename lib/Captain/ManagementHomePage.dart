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
      extendBody:
          true, // Allows the body to flow underneath the floating nav bar
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
          // Keep the primary navigation visible for all three main tabs, but
          // never while the side drawer is open.
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
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(3, (index) {
                final isSelected = _selectedIndex == index;
                final IconData iconData = switch (index) {
                  0 => Icons.home,
                  1 => Icons.announcement,
                  _ => Icons.history,
                };

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
                              ? Colors.black
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected
                          ? Colors.black
                          : Colors.black87,
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
