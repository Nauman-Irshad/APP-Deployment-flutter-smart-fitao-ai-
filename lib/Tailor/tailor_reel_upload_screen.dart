import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../config/production_urls.dart';
import '../Order-Tracking-System/services/app_backend.dart';
import '../services/reel_catalog_service.dart';
import '../services/tailor_reel_upload_service.dart';

/// Tailor uploads a reel from gallery → local server / Firestore → marketplace Reel tab.
class TailorReelUploadScreen extends StatefulWidget {
  const TailorReelUploadScreen({super.key, this.openGalleryOnStart = false});

  /// When opened from menu bar, open gallery immediately.
  final bool openGalleryOnStart;

  @override
  State<TailorReelUploadScreen> createState() => _TailorReelUploadScreenState();
}

class _TailorReelUploadScreenState extends State<TailorReelUploadScreen> {
  final _title = TextEditingController(text: 'My tailoring reel');
  bool _saving = false;
  bool _picking = false;
  String? _status;
  XFile? _pickedVideo;
  String? _uploadedUrl;
  AppUserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    if (widget.openGalleryOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickFromGallery());
    }
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final p = await AppBackend.instance.getUserProfile(uid);
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _status = null;
    });
    try {
      var file = await TailorReelUploadService.pickVideoFromGallery();
      if (file == null) {
        final pf = await TailorReelUploadService.pickVideoFile();
        if (pf != null && pf.bytes != null) {
          file = XFile.fromData(
            Uint8List.fromList(pf.bytes!),
            name: pf.name.isNotEmpty ? pf.name : 'reel.mp4',
            mimeType: 'video/mp4',
          );
        }
      }
      if (!mounted) return;
      if (file == null) {
        setState(() => _status = 'No video selected');
        return;
      }
      setState(() {
        _pickedVideo = file;
        _uploadedUrl = null;
        _status = 'Selected: ${file!.name}';
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _upload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in as tailor first')),
      );
      return;
    }
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a reel title')),
      );
      return;
    }
    if (_pickedVideo == null && (_uploadedUrl == null || _uploadedUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a video from gallery first')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      var videoUrl = _uploadedUrl ?? '';
      if (videoUrl.isEmpty && _pickedVideo != null) {
        setState(() => _status = 'Uploading video…');
        final serverOk = await TailorReelUploadService.isServerReachable();
        if (serverOk) {
          videoUrl = await TailorReelUploadService.uploadPickedVideo(
                _pickedVideo!,
                onProgress: (m) {
                  if (mounted) setState(() => _status = m);
                },
              ) ??
              '';
        }
        if (videoUrl.isEmpty) {
          videoUrl = ProductionUrls.reel4Mobile;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Local server offline — saved with demo video URL. Start start-local-product-server.ps1 for your file.',
                ),
              ),
            );
          }
        }
      }

      final profile = _profile ?? await AppBackend.instance.getUserProfile(user.uid);
      final shop = profile.shopName.isNotEmpty ? profile.shopName : profile.name;
      await ReelCatalogService.addTailorReel(
        tailorId: user.uid,
        tailorName: profile.name,
        shopName: shop,
        videoTitle: title,
        videoUrl: videoUrl,
        fallbackVideoUrl: ProductionUrls.reelMobileFallback,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reel uploaded — customers see it on marketplace Reels'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add video'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Pick a video from your gallery. It appears on the marketplace Reel tab with a new-video notification.',
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 120,
            child: OutlinedButton.icon(
              onPressed: _picking ? null : _pickFromGallery,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primary, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _picking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.video_library_outlined, color: primary, size: 32),
              label: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  _pickedVideo == null ? 'Choose from gallery' : 'Change video',
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Reel title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _upload,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_saving ? 'Uploading…' : 'Upload reel'),
            ),
          ),
        ],
      ),
    );
  }
}
