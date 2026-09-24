import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const _ink = Color(0xFF12233F);
const _page = Color(0xFFF5F8FF);
const _blue = Color(0xFF2864A7);

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: _page,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Text('League information', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('league_info').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _ink));
          }
          if (snapshot.hasError) {
            return _InfoState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load information',
              message: snapshot.error.toString(),
            );
          }
          final documents = snapshot.data?.docs ?? [];
          if (documents.isEmpty) {
            return const _InfoState(
              icon: Icons.info_outline,
              title: 'No league information yet',
              message: 'League updates will appear here when available.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: documents.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) return const _LeagueHero();
              return _LeagueInfoCard(info: documents[index - 1].data());
            },
          );
        },
      ),
    );
  }
}

class _LeagueHero extends StatelessWidget {
  const _LeagueHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 166,
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
            right: -10,
            top: -28,
            child: Icon(Icons.emoji_events_outlined, size: 178, color: Color(0x33728EC5)),
          ),
          const Positioned(
            right: 25,
            bottom: 20,
            child: Icon(Icons.groups_rounded, size: 39, color: _blue),
          ),
          Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.76),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'HOSTEL LEAGUE',
                    style: TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .65),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'One league. One spirit.',
                  style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.5),
                ),
                const SizedBox(height: 5),
                const SizedBox(
                  width: 235,
                  child: Text(
                    'Learn about the people and purpose behind the competition.',
                    style: TextStyle(color: Color(0xFF3B5474), fontSize: 13, height: 1.35),
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

class _LeagueInfoCard extends StatelessWidget {
  const _LeagueInfoCard({required this.info});

  final Map<String, dynamic> info;

  @override
  Widget build(BuildContext context) {
    final about = (info['about_league'] ?? '').toString();
    return Column(
      children: [
        _AboutCard(body: about.isEmpty ? 'League information will be shared shortly.' : about),
        const SizedBox(height: 14),
        _MessageCard(
          label: "Father's message",
          name: (info['fathers_name'] ?? 'Father').toString(),
          role: 'Asst. Financial Administrator and Hostel Manager',
          message: (info['fathers_message'] ?? '').toString(),
          imageUrl: (info['Fathers_image'] ?? '').toString(),
          accent: const Color(0xFF2864A7),
          icon: Icons.account_balance_outlined,
        ),
        const SizedBox(height: 14),
        _MessageCard(
          label: "Warden's message",
          name: (info['wardens_name'] ?? 'Warden').toString(),
          role: 'Hostel Warden',
          message: (info['wardens_message'] ?? '').toString(),
          imageUrl: (info['wardens_image'] ?? '').toString(),
          accent: const Color(0xFF147A72),
          icon: Icons.volunteer_activism_outlined,
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0xFFEAF3FF), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_outlined, color: _blue, size: 22),
          ),
          const SizedBox(height: 17),
          const Text(
            'ABOUT THE LEAGUE',
            style: TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 5),
          const Text('More than a competition', style: TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 11),
          Text(body, style: const TextStyle(color: Color(0xFF53627A), fontSize: 15, height: 1.55)),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.label,
    required this.name,
    required this.role,
    required this.message,
    required this.imageUrl,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String name;
  final String role;
  final String message;
  final String imageUrl;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MessageAvatar(imageUrl: imageUrl, accent: accent, icon: icon),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(role, style: const TextStyle(color: Color(0xFF64738A), fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            message.isEmpty ? 'A message will be shared shortly.' : message,
            style: const TextStyle(color: Color(0xFF53627A), height: 1.55, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _MessageAvatar extends StatelessWidget {
  const _MessageAvatar({required this.imageUrl, required this.accent, required this.icon});

  final String imageUrl;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: accent.withOpacity(.18), shape: BoxShape.circle),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? Container(color: accent.withOpacity(.14), child: Icon(icon, color: accent, size: 27))
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: accent.withOpacity(.14), child: Icon(icon, color: accent, size: 27)),
              ),
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFDCE3F0)),
  boxShadow: const [
    BoxShadow(color: Color(0x120D3065), blurRadius: 18, offset: Offset(0, 7)),
  ],
);

class _InfoState extends StatelessWidget {
  const _InfoState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF64738A), size: 42),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64738A))),
          ],
        ),
      ),
    );
  }
}
