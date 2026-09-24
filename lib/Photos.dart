import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF7),
        foregroundColor: const Color(0xFF171717),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Text('Photo gallery', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('gallery_photos')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF171717)));
          }
          if (snapshot.hasError) {
            return _GalleryState(
              icon: Icons.cloud_off_outlined,
              title: 'Unable to load photos',
              message: snapshot.error.toString(),
            );
          }
          final photos = (snapshot.data?.docs ?? [])
              .where((document) => (document.data()['url'] ?? '').toString().isNotEmpty)
              .toList();
          if (photos.isEmpty) {
            return const _GalleryState(
              icon: Icons.photo_library_outlined,
              title: 'No photos yet',
              message: 'League photos will appear here when they are added.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .78,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) => _PhotoTile(data: photos[index].data()),
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final url = data['url'].toString();
    final year = (data['year'] ?? '').toString();
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FullScreenGalleryPhoto(url: url))),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Color(0xFFE34848))),
                  errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFFC5C1BA), size: 34)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                const Icon(Icons.photo_outlined, size: 16, color: Color(0xFFE34848)),
                const SizedBox(width: 6),
                Text(year.isEmpty ? 'League photo' : year, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class FullScreenGalleryPhoto extends StatelessWidget {
  const FullScreenGalleryPhoto({super.key, required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
    body: Center(
      child: InteractiveViewer(
        minScale: .8,
        maxScale: 4,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const CircularProgressIndicator(color: Colors.white),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 46),
        ),
      ),
    ),
  );
}

class _GalleryState extends StatelessWidget {
  const _GalleryState({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: const Color(0xFF706B64), size: 42),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF706B64))),
      ]),
    ),
  );
}
