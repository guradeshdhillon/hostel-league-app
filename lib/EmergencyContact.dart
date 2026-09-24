import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _ink = Color(0xFF12233F);
const _page = Color(0xFFF5F8FF);
const _blue = Color(0xFF2864A7);

class EmergencyContactScreen extends StatelessWidget {
  EmergencyContactScreen({super.key});

  final List<Map<String, String>> contacts = const [
    {'name': 'Fr. Roby', 'phone': '+91 9686018612'},
    {'name': 'Roy Joseph', 'phone': '+91 7776860002'},
    {'name': 'Hostel Reception', 'phone': '+91 9403554750'},
    {'name': 'Steavo Babu', 'phone': '+91 9699579704'},
    {'name': 'Atharva Men', 'phone': '+91 7499752762'},
    {'name': 'Omkar Gangamwar', 'phone': '+91 8766734653'},
    {'name': 'Om Gawande', 'phone': '+91 9766839371'},
    {'name': 'Gaurav Pidurkar', 'phone': '+91 8788498617'},
  ];

  Future<void> _launchPhone(BuildContext context, String phoneNumber) async {
    final phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(phoneUri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the phone app.')),
      );
    }
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
        title: const Text('Emergency contacts', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: contacts.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) return const _EmergencyHero();
          final contact = contacts[index - 1];
          final accent = _contactAccent(index - 1);
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(19),
            child: InkWell(
              borderRadius: BorderRadius.circular(19),
              onTap: () => _launchPhone(context, contact['phone']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0xFFDCE3F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x120D3065), blurRadius: 18, offset: Offset(0, 7)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(color: accent.withOpacity(.13), shape: BoxShape.circle),
                      child: Icon(
                        contact['name'] == 'Hostel Reception' ? Icons.support_agent_rounded : Icons.person_outline_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact['name']!, style: const TextStyle(color: _ink, fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(contact['phone']!, style: const TextStyle(color: Color(0xFF64738A), fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      width: 39,
                      height: 39,
                      decoration: const BoxDecoration(color: Color(0xFFEAF3FF), shape: BoxShape.circle),
                      child: const Icon(Icons.call_outlined, color: _blue, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmergencyHero extends StatelessWidget {
  const _EmergencyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
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
            right: -15,
            top: -28,
            child: Icon(Icons.contact_phone_outlined, size: 176, color: Color(0x33728EC5)),
          ),
          const Positioned(
            right: 25,
            bottom: 20,
            child: Icon(Icons.phone_in_talk_outlined, size: 38, color: _blue),
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
                    'QUICK SUPPORT',
                    style: TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .65),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Help is one tap away.',
                  style: TextStyle(color: _ink, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.5),
                ),
                const SizedBox(height: 5),
                const SizedBox(
                  width: 232,
                  child: Text(
                    'Choose a contact below to call them directly.',
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

Color _contactAccent(int index) {
  const colors = [Color(0xFF2864A7), Color(0xFF147A72), Color(0xFF7951B8), Color(0xFFE06B3C)];
  return colors[index % colors.length];
}
