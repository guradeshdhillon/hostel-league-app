import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ScoreboardScreen extends StatelessWidget {
  
  String _getTeamLogo(String teamName) {
    switch (teamName) {
      case 'Black Eagles':
        return 'assets/logo1.png';
      case 'Anna Warriors':
        return 'assets/logo2.png';
      case 'Defending Titans':
        return 'assets/logo3.png';
      case 'White Walkers':
        return 'assets/logo4.png';
      case 'The Scout Regiment':
        return 'assets/logo5.png';
      case 'Retro Rivals':
        return 'assets/logo6.png';
      case 'Rising Giants':
        return 'assets/logo7.png';
      default:
        return 'assets/logo.png';
    }
  }

  Widget _buildMedal(int rank) {
    return Image.asset(
      'assets/medal_$rank.png',
      width: 75,
      height: 75,
      fit: BoxFit.contain,
    );
  }

  Widget _buildPodiumBlock(BuildContext context, DocumentSnapshot? teamDoc, int rank, double height, Color color) {
    if (teamDoc == null) {
      return Expanded(child: Container());
    }
    
    final teamName = teamDoc.id;
    final score = teamDoc['score'].toString();
    final logoPath = _getTeamLogo(teamName);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(logoPath, width: 50, height: 50, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Score
          Text(
            score,
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          // Stack to guarantee independent rendering without nested clipping
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Podium Box (3D)
              Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.9), // Top face simulated
                      color.withOpacity(0.6),
                      color.withOpacity(0.3),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(5, -5), // Simulating light from top right
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(-5, 5), // Simulating shadow on the bottom left
                    ),
                  ],
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
                    right: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                  ),
                ),
              ),
              // MEDAL - Guaranteed to render on top of the podium, perfectly centered!
              _buildMedal(rank),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.orange.withOpacity(0.3), Colors.transparent],
                  radius: 0.8,
                  center: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // Light Rays from Top Right
          Positioned(
            top: -50,
            right: -100,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                height: 400,
                width: 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.15), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'Leaderboard',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 48), // Balances the back button to perfectly center the text
                    ],
                  ),
                ),
                
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestore.collection('teams').orderBy('score', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.orange));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No data available', style: TextStyle(color: Colors.white)));
                      }

                      final teams = snapshot.data!.docs;
                      final top1 = teams.isNotEmpty ? teams[0] : null;
                      final top2 = teams.length > 1 ? teams[1] : null;
                      final top3 = teams.length > 2 ? teams[2] : null;
                      final remainingTeams = teams.length > 3 ? teams.sublist(3) : [];

                      return Column(
                        children: [
                          // Podium Area
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // 2nd Place
                                  _buildPodiumBlock(context, top2, 2, 140, Colors.orange),
                                  // 1st Place
                                  _buildPodiumBlock(context, top1, 1, 190, Colors.orangeAccent),
                                  // 3rd Place
                                  _buildPodiumBlock(context, top3, 3, 110, Colors.deepOrange),
                                ],
                              ),
                            ),
                          ),
                          // Bottom Drawer
                          Expanded(
                            flex: 5,
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 24),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      itemCount: remainingTeams.length,
                                      itemBuilder: (context, index) {
                                        final team = remainingTeams[index];
                                        final rank = index + 4;
                                        final teamName = team.id;
                                        final score = team['score'];
                                        final logoPath = _getTeamLogo(teamName);

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 12.0),
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2C2C2C),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            children: [
                                              // Rank
                                              SizedBox(
                                                width: 30,
                                                child: Text(
                                                  '$rank',
                                                  style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 16),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Avatar
                                              Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Image.asset(logoPath, width: 40, height: 40, fit: BoxFit.cover),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Team Name
                                              Expanded(
                                                child: Text(
                                                  teamName,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                              // Score
                                              Text(
                                                score.toString(),
                                                style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
