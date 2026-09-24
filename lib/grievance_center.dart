import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const _pageColor = Color(0xFFF5F8FF);
const _ink = Color(0xFF12233F);
const _blue = Color(0xFF2864A7);

class GrievanceCenter extends StatelessWidget {
  const GrievanceCenter({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        backgroundColor: _pageColor,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          isAdmin ? 'Grievances' : 'My grievances',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 25),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('grievances')
            .orderBy('submittedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _ink));
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load grievances',
              message: snapshot.error.toString(),
            );
          }
          final grievances = snapshot.data?.docs ?? [];
          if (grievances.isEmpty) {
            return _MessageState(
              icon: Icons.forum_outlined,
              title: 'No grievances yet',
              message: isAdmin
                  ? 'New reports submitted by captains will appear here.'
                  : 'Use the button below to raise a concern.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: grievances.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _GrievanceCard(
              document: grievances[index],
              isAdmin: isAdmin,
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add),
              label: const Text('Raise grievance'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GrievanceFormScreen()),
              ),
            ),
    );
  }
}

class _GrievanceHero extends StatelessWidget {
  const _GrievanceHero({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
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
            top: -25,
            child: Icon(Icons.forum_outlined, size: 166, color: Color(0x33728EC5)),
          ),
          const Positioned(
            right: 25,
            bottom: 20,
            child: Icon(Icons.rate_review_outlined, size: 38, color: _blue),
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
                    'GRIEVANCE DESK',
                    style: TextStyle(color: _blue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .65),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isAdmin ? 'Review with clarity.' : 'Your voice matters.',
                  style: const TextStyle(color: _ink, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.5),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 235,
                  child: Text(
                    isAdmin
                        ? 'Track reports, review details and keep every decision up to date.'
                        : 'Raise a concern and follow its review status in one place.',
                    style: const TextStyle(color: Color(0xFF3B5474), fontSize: 13, height: 1.35),
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

class _GrievanceCard extends StatelessWidget {
  const _GrievanceCard({required this.document, required this.isAdmin});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final status = (data['status'] ?? 'Pending').toString();
    final attachments = List<Map<String, dynamic>>.from(
      (data['attachments'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)),
    );
    final submittedAt = data['submittedAt'] as Timestamp?;
    final title = (data['grievanceRelatedTo'] ?? 'Grievance').toString();
    final message = (data['grievanceMessage'] ?? '').toString();
    final statusColor = _statusColor(status);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GrievanceDetailScreen(
              document: document,
              isAdmin: isAdmin,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE3F0)),
            boxShadow: const [
              BoxShadow(color: Color(0x120D3065), blurRadius: 18, offset: Offset(0, 7)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: statusColor, width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon(status), color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                        ),
                        _StatusPill(status: status),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message.isEmpty ? 'No description provided' : message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF53627A), height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          (data['name'] ?? 'Unknown').toString(),
                          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        const Spacer(),
                        if (attachments.isNotEmpty) ...[
                          const Icon(Icons.attach_file, size: 15, color: Color(0xFF64738A)),
                          const SizedBox(width: 3),
                          Text('${attachments.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF64738A))),
                          const SizedBox(width: 10),
                        ],
                        if (submittedAt != null)
                          Text(
                            DateFormat('dd MMM').format(submittedAt.toDate()),
                            style: const TextStyle(color: Color(0xFF64738A), fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GrievanceDetailScreen extends StatefulWidget {
  const GrievanceDetailScreen({super.key, required this.document, required this.isAdmin});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final bool isAdmin;

  @override
  State<GrievanceDetailScreen> createState() => _GrievanceDetailScreenState();
}

class _GrievanceDetailScreenState extends State<GrievanceDetailScreen> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = (widget.document.data()['status'] ?? 'Pending').toString();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data();
    final attachments = List<Map<String, dynamic>>.from(
      (data['attachments'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)),
    );
    final submittedAt = data['submittedAt'] as Timestamp?;

    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        backgroundColor: _pageColor,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Grievance details', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _panelDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      (data['grievanceRelatedTo'] ?? 'Grievance').toString(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                  _StatusPill(status: _status),
                ]),
                const SizedBox(height: 16),
                Text(
                  (data['grievanceMessage'] ?? 'No description provided.').toString(),
                  style: const TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF53627A)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _panelDecoration,
            child: Column(
              children: [
                _InfoRow(label: 'Submitted by', value: (data['name'] ?? '—').toString()),
                _InfoRow(label: 'Team', value: (data['team'] ?? '—').toString()),
                _InfoRow(label: 'Match reference', value: (data['matchId'] ?? '').toString().isEmpty ? 'Not provided' : data['matchId'].toString()),
                _InfoRow(
                  label: 'Submitted',
                  value: submittedAt == null ? 'Just now' : DateFormat('dd MMM yyyy, h:mm a').format(submittedAt.toDate()),
                  isLast: true,
                ),
              ],
            ),
          ),
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 8),
            ...attachments.map((attachment) => _AttachmentTile(attachment: attachment)),
          ],
          if (widget.isAdmin) ...[
            const SizedBox(height: 22),
            _StatusSelector(
              document: widget.document,
              currentStatus: _status,
              onStatusUpdated: (status) => setState(() => _status = status),
            ),
          ],
        ],
      ),
    );
  }
}

class GrievanceFormScreen extends StatefulWidget {
  const GrievanceFormScreen({super.key});

  @override
  State<GrievanceFormScreen> createState() => _GrievanceFormScreenState();
}

class _GrievanceFormScreenState extends State<GrievanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _matchController = TextEditingController();
  final _messageController = TextEditingController();
  final List<PlatformFile> _attachments = [];
  String? _team;
  String? _type;
  bool _submitting = false;

  static const _teams = [
    'Anna Warriors', 'Black Eagles', 'Defending Titans', 'White Walkers',
    'The Scout Regiment', 'Retro Rivals', 'Rising Giants',
  ];
  static const _types = ['Biased decision', 'Unfair play', 'Player eligibility', 'Conduct', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _matchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final selection = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'm4v'],
    );
    if (selection == null || !mounted) return;
    setState(() {
      for (final file in selection.files) {
        if (!_attachments.any((item) => item.path == file.path)) _attachments.add(file);
      }
    });
  }

  bool _isVideo(PlatformFile file) => const ['mp4', 'mov', 'm4v'].contains(file.extension?.toLowerCase());

  Future<List<Map<String, String>>> _uploadAttachments(String grievanceId) async {
    final uploads = <Map<String, String>>[];
    for (final file in _attachments) {
      if (file.path == null) continue;
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ref = FirebaseStorage.instance.ref('grievances/$grievanceId/$timestamp-$safeName');
      await ref.putFile(File(file.path!));
      uploads.add({
        'name': file.name,
        'url': await ref.getDownloadURL(),
        'type': _isVideo(file) ? 'video' : 'image',
      });
    }
    return uploads;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final reference = FirebaseFirestore.instance.collection('grievances').doc();
      var attachments = <Map<String, String>>[];
      var attachmentsUnavailable = false;

      // Evidence is optional. A disabled Storage bucket must never prevent a
      // grievance from reaching Firestore.
      if (_attachments.isNotEmpty) {
        try {
          attachments = await _uploadAttachments(reference.id);
        } catch (_) {
          attachmentsUnavailable = true;
        }
      }
      await reference.set({
        'name': _nameController.text.trim(),
        'team': _team,
        'matchId': _matchController.text.trim(),
        'grievanceRelatedTo': _type,
        'grievanceMessage': _messageController.text.trim(),
        'attachments': attachments,
        'hasProof': attachments.isEmpty ? 'No' : 'Yes',
        'submittedAt': Timestamp.now(),
        'status': 'Pending',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attachmentsUnavailable
                ? 'Grievance submitted without attachments. Firebase Storage is currently unavailable.'
                : 'Grievance submitted successfully.',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit grievance: $error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        backgroundColor: _pageColor,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Raise a grievance', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              const Text('Share the details clearly. Your report will be reviewed by management.', style: TextStyle(color: Color(0xFF53627A), height: 1.4)),
              const SizedBox(height: 20),
              _FieldLabel('Your name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Enter your name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Team'),
              DropdownButtonFormField<String>(
                value: _team,
                decoration: _inputDecoration('Select your team'),
                items: _teams.map((team) => DropdownMenuItem(value: team, child: Text(team))).toList(),
                onChanged: (value) => setState(() => _team = value),
                validator: (value) => value == null ? 'Please select your team' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Grievance type'),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: _inputDecoration('Select a category'),
                items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _type = value),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              _FieldLabel('Match reference (optional)'),
              TextFormField(controller: _matchController, decoration: _inputDecoration('Match number or event name')),
              const SizedBox(height: 16),
              _FieldLabel('Describe the issue'),
              TextFormField(
                controller: _messageController,
                minLines: 5,
                maxLines: 7,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration('Explain what happened and any relevant details.'),
                validator: (value) => value == null || value.trim().length < 10 ? 'Please provide a little more detail' : null,
              ),
              const SizedBox(height: 20),
              _FieldLabel('Evidence (optional)'),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickAttachments,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add photos or videos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  side: const BorderSide(color: Color(0xFFD8D3CB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                ..._attachments.asMap().entries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(_isVideo(entry.value) ? Icons.videocam_outlined : Icons.image_outlined),
                    const SizedBox(width: 10),
                    Expanded(child: Text(entry.value.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 19),
                      onPressed: _submitting ? null : () => setState(() => _attachments.removeAt(entry.key)),
                    ),
                  ]),
                )),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit grievance', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _panelDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: const Color(0xFFDCE3F0)),
  boxShadow: const [
    BoxShadow(color: Color(0x120D3065), blurRadius: 18, offset: Offset(0, 7)),
  ],
);

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF8A98AB)),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE3F0))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE3F0))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _blue, width: 1.4)),
);

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.isLast = false});
  final String label;
  final String value;
  final bool isLast;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFEDF1F7)))),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF64738A)))),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
    ]),
  );
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});
  final Map<String, dynamic> attachment;
  @override
  Widget build(BuildContext context) {
    final isVideo = attachment['type'] == 'video';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final url = Uri.tryParse((attachment['url'] ?? '').toString());
            if (url != null) await launchUrl(url, mode: LaunchMode.externalApplication);
          },
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: _panelDecoration,
            child: Row(children: [
              Icon(isVideo ? Icons.videocam_outlined : Icons.image_outlined),
              const SizedBox(width: 10),
              Expanded(child: Text((attachment['name'] ?? 'Attachment').toString(), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.open_in_new, size: 18),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'resolved' || 'approved' => const Color(0xFF18794E),
  'rejected' => const Color(0xFFE34848),
  'pending' => const Color(0xFFE0A100),
  'in review' => const Color(0xFFB06C00),
  _ => const Color(0xFF5F5B55),
};

IconData _statusIcon(String status) => switch (status.toLowerCase()) {
  'resolved' || 'approved' => Icons.task_alt_rounded,
  'rejected' => Icons.cancel_outlined,
  'in review' => Icons.manage_search_rounded,
  'pending' => Icons.priority_high_rounded,
  _ => Icons.info_outline_rounded,
};

class _StatusSelector extends StatefulWidget {
  const _StatusSelector({
    required this.document,
    required this.currentStatus,
    required this.onStatusUpdated,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final String currentStatus;

  final ValueChanged<String> onStatusUpdated;

  @override
  State<_StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<_StatusSelector> {
  static const _statuses = ['Pending', 'In review', 'Resolved', 'Rejected'];
  late String _selectedStatus;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _statuses.contains(widget.currentStatus) ? widget.currentStatus : 'Pending';
  }

  @override
  void didUpdateWidget(covariant _StatusSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSaving && oldWidget.currentStatus != widget.currentStatus) {
      _selectedStatus = _statuses.contains(widget.currentStatus) ? widget.currentStatus : 'Pending';
    }
  }

  Future<void> _save() async {
    if (_selectedStatus == widget.currentStatus) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.document.reference.update({
        'status': _selectedStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      widget.onStatusUpdated(_selectedStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $_selectedStatus.')),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.code == 'permission-denied'
            ? 'Firebase denied this update. Check that management users can update grievances in Firestore Rules.'
            : 'Could not update status: ${error.message ?? error.code}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not update the status. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasChange = _selectedStatus != widget.currentStatus;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resolution status', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            'Select the current review outcome, then save the change.',
            style: TextStyle(color: _ink.withOpacity(.62), fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.flag_outlined),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD5D1CA)),
              ),
            ),
            items: _statuses
                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
            onChanged: _isSaving
                ? null
                : (status) {
                    if (status != null) setState(() => _selectedStatus = status);
                  },
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12, height: 1.35)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSaving || !hasChange ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE4E1DB),
                disabledForegroundColor: const Color(0xFF8B8780),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 19),
              label: Text(_isSaving ? 'Updating…' : 'Update status', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 42, color: const Color(0xFF6E6962)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF706B64))),
      ]),
    ),
  );
}
