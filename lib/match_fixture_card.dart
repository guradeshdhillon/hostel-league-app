import 'package:flutter/material.dart';

class MatchFixtureCard extends StatelessWidget {
  const MatchFixtureCard({
    super.key,
    required this.match,
    required this.dateLabel,
    required this.onTap,
  });

  final Map<String, dynamic> match;
  final String dateLabel;
  final VoidCallback onTap;

  static const _logos = {
    'Black Eagles': 'assets/logo1.png',
    'Anna Warriors': 'assets/logo2.png',
    'Defending Titans': 'assets/logo3.png',
    'White Walkers': 'assets/logo4.png',
    'The Scout Regiment': 'assets/logo5.png',
    'Retro Rivals': 'assets/logo6.png',
    'Rising Giants': 'assets/logo7.png',
  };

  int get _points {
    final value = match['points'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final team1 = (match['team1_name'] ?? 'Team one').toString();
    final team2 = (match['team2_name'] ?? 'Team two').toString();
    final winner = (match['won_by'] ?? '').toString();
    final team1Score = winner == team1 ? _points : 0;
    final team2Score = winner == team2 ? _points : 0;
    final sport = (match['sports'] ?? 'Match').toString();
    final matchNumber = (match['match_number'] ?? 'Match').toString();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE3F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x120D3065), blurRadius: 18, offset: Offset(0, 7)),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      matchNumber.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF2864A7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8),
                    ),
                  ),
                  Text(dateLabel, style: const TextStyle(color: Color(0xFF64738A), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _TeamSide(name: team1, asset: _logos[team1], alignEnd: false)),
                  SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        Text('$team1Score  –  $team2Score', style: const TextStyle(color: Color(0xFF12233F), fontSize: 29, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Expanded(child: _TeamSide(name: team2, asset: _logos[team2], alignEnd: true)),
                ],
              ),
              const SizedBox(height: 13),
              Container(height: 1, color: const Color(0xFFEDF1F7)),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(Icons.sports_outlined, color: Color(0xFF2864A7), size: 15),
                  const SizedBox(width: 6),
                  Expanded(child: Text(sport, style: const TextStyle(color: Color(0xFF53627A), fontSize: 12, fontWeight: FontWeight.w700))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.name, required this.asset, required this.alignEnd});
  final String name;
  final String? asset;
  final bool alignEnd;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
      Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: asset == null
            ? const Icon(Icons.shield_outlined, color: Color(0xFF12233F), size: 22)
            : Padding(padding: const EdgeInsets.all(6), child: Image.asset(asset!, fit: BoxFit.contain)),
      ),
      const SizedBox(height: 6),
      Text(
        name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: const TextStyle(color: Color(0xFF12233F), fontSize: 11, fontWeight: FontWeight.w800, height: 1.1),
      ),
    ],
  );
}
