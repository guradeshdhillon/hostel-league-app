import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _rosterInk = Color(0xFF12233F);
const _rosterPage = Color(0xFFF5F8FF);
const _rosterBlue = Color(0xFF2864A7);

class TeamRosterScreen extends StatefulWidget {
  const TeamRosterScreen({super.key, required this.teamName, required this.isAdmin});

  final String teamName;
  final bool isAdmin;

  @override
  State<TeamRosterScreen> createState() => _TeamRosterScreenState();
}

class _TeamRosterScreenState extends State<TeamRosterScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleBlocked(QueryDocumentSnapshot<Map<String, dynamic>> player) async {
    final blocked = _isBlocked(player.data()['player_status']);
    final action = blocked ? 'unblock' : 'block';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${blocked ? 'Unblock' : 'Block'} player?'),
        content: Text('Do you want to $action ${(player.data()['name'] ?? 'this player').toString()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(blocked ? 'Unblock' : 'Block')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await player.reference.update({'player_status': blocked ? 'false' : 'true'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked ? 'Player unblocked.' : 'Player blocked.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update player: ${error.message ?? error.code}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _rosterPage,
      appBar: AppBar(
        backgroundColor: _rosterPage,
        foregroundColor: _rosterInk,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 8,
        title: Text(widget.teamName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 23)),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: _rosterBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add player'),
              onPressed: () => _showAddPlayerSheet(context, widget.teamName),
            )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection(widget.teamName).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _rosterBlue));
          }
          if (snapshot.hasError) {
            return _RosterMessage(icon: Icons.cloud_off_outlined, title: 'Unable to load players', message: snapshot.error.toString());
          }

          final players = [...(snapshot.data?.docs ?? [])]
            ..sort((a, b) => _playerName(a).toLowerCase().compareTo(_playerName(b).toLowerCase()));
          final filtered = players.where((player) => _playerName(player).toLowerCase().contains(_query.toLowerCase())).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _RosterSearch(
                  controller: _searchController,
                  count: filtered.length,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _RosterMessage(
                        icon: _query.isEmpty ? Icons.groups_outlined : Icons.search_off_rounded,
                        title: _query.isEmpty ? 'No players yet' : 'No matching player',
                        message: _query.isEmpty ? 'Players added to ${widget.teamName} will appear here.' : 'Try a different name.',
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(16, 2, 16, widget.isAdmin ? 100 : 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _PlayerCard(
                          player: filtered[index],
                          accent: _accentForIndex(index),
                          isAdmin: widget.isAdmin,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PlayerDetailsScreen(player: filtered[index], teamName: widget.teamName)),
                          ),
                          onLongPress: widget.isAdmin ? () => _toggleBlocked(filtered[index]) : null,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RosterSearch extends StatelessWidget {
  const _RosterSearch({required this.controller, required this.count, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final int count;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search player by name',
            hintStyle: const TextStyle(color: Color(0xFF8A98AB)),
            prefixIcon: const Icon(Icons.search_rounded, color: _rosterBlue),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.close_rounded), color: const Color(0xFF64738A), onPressed: onClear),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFDCE3F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFDCE3F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: _rosterBlue, width: 1.4)),
          ),
        ),
        const SizedBox(height: 10),
        Text('$count ${count == 1 ? 'player' : 'players'}', style: const TextStyle(color: Color(0xFF64738A), fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player,
    required this.accent,
    required this.isAdmin,
    required this.onTap,
    required this.onLongPress,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> player;
  final Color accent;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final data = player.data();
    final name = _playerName(player);
    final blocked = _isBlocked(data['player_status']);
    final sports = _sportsOf(data['sports']);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE3F0)),
            boxShadow: const [BoxShadow(color: Color(0x120D3065), blurRadius: 15, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(color: accent.withOpacity(.14), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(_initials(name), style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 15)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: _rosterInk, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 7),
                    if (blocked)
                      const _StatusBadge(label: 'Blocked', color: Color(0xFFB42318))
                    else if (sports.isEmpty)
                      const Text('No sports selected', style: TextStyle(color: Color(0xFF64738A), fontSize: 12))
                    else
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: sports.take(3).map((sport) => _SportChip(label: sport, color: accent)).toList(),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF7B8BA2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SportChip extends StatelessWidget {
  const _SportChip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 10)),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
      );
}

class PlayerDetailsScreen extends StatelessWidget {
  const PlayerDetailsScreen({super.key, required this.player, required this.teamName});
  final QueryDocumentSnapshot<Map<String, dynamic>> player;
  final String teamName;

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open the phone app.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = player.data();
    final name = _playerName(player);
    final sports = _sportsOf(data['sports']);
    final phone = (data['phone_number'] ?? '').toString();
    final room = (data['room_number'] ?? '').toString();
    final year = (data['year'] ?? '').toString();
    return Scaffold(
      backgroundColor: _rosterPage,
      appBar: AppBar(backgroundColor: _rosterPage, foregroundColor: _rosterInk, elevation: 0, surfaceTintColor: Colors.transparent, title: const Text('Player details', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _detailDecoration,
            child: Column(
              children: [
                Container(width: 76, height: 76, alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFFEAF3FF), shape: BoxShape.circle), child: Text(_initials(name), style: const TextStyle(color: _rosterBlue, fontSize: 23, fontWeight: FontWeight.w900))),
                const SizedBox(height: 13),
                Text(name, textAlign: TextAlign.center, style: const TextStyle(color: _rosterInk, fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(teamName, style: const TextStyle(color: Color(0xFF64738A), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: _detailDecoration,
            child: Column(
              children: [
                _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: phone.isEmpty ? 'Not provided' : phone),
                _DetailRow(icon: Icons.meeting_room_outlined, label: 'Room', value: room.isEmpty ? 'Not provided' : room),
                _DetailRow(icon: Icons.school_outlined, label: 'Year', value: year.isEmpty ? 'Not provided' : year, isLast: true),
              ],
            ),
          ),
          if (sports.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('Sports', style: TextStyle(color: _rosterInk, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 9),
            Wrap(spacing: 7, runSpacing: 7, children: sports.map((sport) => _SportChip(label: sport, color: _rosterBlue)).toList()),
          ],
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: () => _call(context, phone), icon: const Icon(Icons.call_outlined), label: const Text('Call player'), style: FilledButton.styleFrom(backgroundColor: _rosterBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))))),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value, this.isLast = false});
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFEDF1F7)))),
        child: Row(children: [Icon(icon, color: _rosterBlue, size: 19), const SizedBox(width: 10), Text(label, style: const TextStyle(color: Color(0xFF64738A))), const Spacer(), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: _rosterInk, fontWeight: FontWeight.w800)))]),
      );
}

class _RosterMessage extends StatelessWidget {
  const _RosterMessage({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFF64738A), size: 42), const SizedBox(height: 14), Text(title, style: const TextStyle(color: _rosterInk, fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64738A)))])));
}

Future<void> _showAddPlayerSheet(BuildContext context, String teamName) async {
  final name = TextEditingController();
  final phone = TextEditingController();
  final room = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var saving = false;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 22, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add player', style: TextStyle(color: _rosterInk, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 17),
              _addField(name, 'Player name', Icons.person_outline, required: true),
              const SizedBox(height: 11),
              _addField(phone, 'Phone number (optional)', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 11),
              _addField(room, 'Room number (optional)', Icons.meeting_room_outlined),
              const SizedBox(height: 18),
              SizedBox(height: 48, child: FilledButton(onPressed: saving ? null : () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                setSheetState(() => saving = true);
                try {
                  await FirebaseFirestore.instance.collection(teamName).add({'team_name': teamName, 'name': name.text.trim(), 'phone_number': phone.text.trim(), 'room_number': room.text.trim(), 'sports': <String>[], 'player_status': 'false'});
                  if (context.mounted) Navigator.pop(context);
                } on FirebaseException catch (error) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add player: ${error.message ?? error.code}')));
                } finally {
                  if (context.mounted) setSheetState(() => saving = false);
                }
              }, style: FilledButton.styleFrom(backgroundColor: _rosterBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))), child: Text(saving ? 'Adding...' : 'Add player', style: const TextStyle(fontWeight: FontWeight.w800)))),
            ],
          ),
        ),
      ),
    ),
  );
  name.dispose();
  phone.dispose();
  room.dispose();
}

Widget _addField(TextEditingController controller, String hint, IconData icon, {bool required = false, TextInputType? keyboardType}) => TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: _rosterBlue), filled: true, fillColor: const Color(0xFFF8FAFD), border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFDCE3F0))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFDCE3F0)))),
      validator: required ? (value) => (value?.trim().isEmpty ?? true) ? 'Enter the player name' : null : null,
    );

final _detailDecoration = BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFDCE3F0)), boxShadow: const [BoxShadow(color: Color(0x120D3065), blurRadius: 18, offset: Offset(0, 7))]);

String _playerName(QueryDocumentSnapshot<Map<String, dynamic>> player) => (player.data()['name'] ?? 'Unnamed player').toString();
bool _isBlocked(dynamic value) => value == true || value?.toString().toLowerCase() == 'true';
List<String> _sportsOf(dynamic value) => value is Iterable ? value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList() : const [];
String _initials(String value) { final words = value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList(); return words.isEmpty ? '?' : words.take(2).map((word) => word[0]).join().toUpperCase(); }
Color _accentForIndex(int index) { const colors = [Color(0xFF2864A7), Color(0xFF147A72), Color(0xFF7951B8), Color(0xFFE06B3C)]; return colors[index % colors.length]; }
