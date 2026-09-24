import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _ink = Color(0xFF12233F);
const _page = Color(0xFFF5F8FF);

class DevelopersScreen extends StatelessWidget {
  DevelopersScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _developerOrder = const [
    'Kushal Khadgi',
    'Abhishek Wasekar',
    'Nakul Wanjari',
  ];

  Future<void> _openContact(BuildContext context, String value, {required bool whatsapp}) async {
    final uri = whatsapp
        ? Uri.parse('https://wa.me/${value.replaceAll(RegExp(r'[^0-9]'), '')}')
        : Uri(scheme: 'tel', path: value);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this contact option.')),
      );
    }
  }

  int _orderOf(String name) {
    final index = _developerOrder.indexOf(name);
    return index == -1 ? _developerOrder.length : index;
  }

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
        title: const Text('Developers', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('developers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _ink));
          }
          if (snapshot.hasError) {
            return _DeveloperState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load developers',
              message: snapshot.error.toString(),
            );
          }
          final developers = (snapshot.data?.docs ?? []).toList()
            ..sort(
              (a, b) => _orderOf((a.data()['name'] ?? '').toString())
                  .compareTo(_orderOf((b.data()['name'] ?? '').toString())),
            );
          if (developers.isEmpty) {
            return const _DeveloperState(
              icon: Icons.code_off_outlined,
              title: 'No developers listed',
              message: 'Developer contacts will appear here when available.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            itemCount: developers.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) return const _DeveloperHero();
              final data = developers[index - 1].data();
              final name = (data['name'] ?? 'Developer').toString();
              final phone = (data['phone'] ?? '').toString();
              return _DeveloperCard(
                name: name,
                phone: phone,
                imageUrl: (data['imageUrl'] ?? '').toString(),
                accent: _accentForName(name),
                onCall: () => _openContact(context, phone, whatsapp: false),
                onWhatsApp: () => _openContact(context, phone, whatsapp: true),
              );
            },
          );
        },
      ),
    );
  }
}

class _DeveloperHero extends StatelessWidget {
  const _DeveloperHero();

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
            right: -8,
            top: -22,
            child: Icon(Icons.data_object_rounded, size: 170, color: Color(0x35728EC5)),
          ),
          const Positioned(
            right: 24,
            bottom: 21,
            child: Icon(Icons.terminal_rounded, size: 40, color: Color(0xFF2864A7)),
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
                    'HOSTEL LEAGUE PRODUCT TEAM',
                    style: TextStyle(color: Color(0xFF2864A7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .65),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Built with care.',
                  style: TextStyle(color: _ink, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.5),
                ),
                const SizedBox(height: 5),
                const SizedBox(
                  width: 225,
                  child: Text(
                    'Meet the people keeping your league experience running smoothly.',
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

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({
    required this.name,
    required this.phone,
    required this.imageUrl,
    required this.accent,
    required this.onCall,
    required this.onWhatsApp,
  });

  final String name;
  final String phone;
  final String imageUrl;
  final Color accent;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              _DeveloperAvatar(name: name, imageUrl: imageUrl, accent: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      phone.isEmpty ? 'Contact unavailable' : phone,
                      style: const TextStyle(color: Color(0xFF64738A), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ContactButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  foreground: const Color(0xFF2864A7),
                  background: const Color(0xFFEAF3FF),
                  onTap: phone.isEmpty ? null : onCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ContactButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp',
                  foreground: const Color(0xFF147A52),
                  background: const Color(0xFFE5F7EF),
                  onTap: phone.isEmpty ? null : onWhatsApp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeveloperAvatar extends StatelessWidget {
  const _DeveloperAvatar({required this.name, required this.imageUrl, required this.accent});

  final String name;
  final String imageUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(.2)),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? _FallbackAvatar(name: name, accent: accent)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackAvatar(name: name, accent: accent),
              ),
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        disabledForegroundColor: const Color(0xFF939EAE),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent,
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 29),
      ),
    );
  }
}

class _DeveloperState extends StatelessWidget {
  const _DeveloperState({required this.icon, required this.title, required this.message});

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

Color _accentForName(String name) {
  const accents = [Color(0xFF2864A7), Color(0xFF7951B8), Color(0xFF147A72), Color(0xFFE06B3C)];
  final value = name.codeUnits.fold<int>(0, (total, character) => total + character);
  return accents[value % accents.length];
}
