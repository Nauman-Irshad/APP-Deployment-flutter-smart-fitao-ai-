import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../Order-Tracking-System/services/app_backend.dart';
import '../services/cloud_media_url.dart';
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
  final _pasteVideoUrl = TextEditingController();
  bool _saving = false;
  bool _picking = false;
  String? _status;
  XFile? _pickedVideo;
  String? _uploadedUrl;
  bool _usingPastedUrl = false;
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
    _pasteVideoUrl.dispose();
    super.dispose();
  }

  void _applyPastedVideoUrl() {
    final url = CloudMediaUrl.normalize(_pasteVideoUrl.text);
    final err = CloudMediaUrl.validateVideoUrl(url);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _usingPastedUrl = true;
      _uploadedUrl = url;
      _pickedVideo = null;
      _status = 'Using online video link — no upload wait';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video link OK — tap Upload reel to publish'),
        backgroundColor: Color(0xFF059669),
      ),
    );
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
        _usingPastedUrl = false;
        _pasteVideoUrl.clear();
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
    if (_pickedVideo == null &&
        (_uploadedUrl == null || _uploadedUrl!.isEmpty) &&
        _pasteVideoUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Choose a video from gallery or paste a Cloudflare / https video link',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      var videoUrl = _uploadedUrl ?? '';
      if (videoUrl.isEmpty && _pasteVideoUrl.text.trim().isNotEmpty) {
        final pasted = CloudMediaUrl.normalize(_pasteVideoUrl.text);
        final err = CloudMediaUrl.validateVideoUrl(pasted);
        if (err != null) throw StateError(err);
        videoUrl = pasted;
      }
      if (videoUrl.isEmpty && _pickedVideo != null) {
        setState(() => _status = 'Uploading your video…');
        videoUrl = await TailorReelUploadService.uploadPickedVideo(
          _pickedVideo!,
          tailorId: user.uid,
          onProgress: (m) {
            if (mounted) setState(() => _status = m);
          },
        );
      }

      if (videoUrl.isEmpty) {
        throw StateError('Could not upload video. Check internet and try again.');
      }

      final profile = _profile ?? await AppBackend.instance.getUserProfile(user.uid);
      final shop = profile.shopName.isNotEmpty ? profile.shopName : profile.name;
      await ReelCatalogService.addTailorReel(
        tailorId: user.uid,
        tailorName: profile.name,
        shopName: shop,
        videoTitle: title,
        videoUrl: videoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploaded successfully — customers see it on Reels with a red notification'),
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
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Paste Cloudflare R2 video link (fast — no upload wait)',
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload .mp4 to R2, copy public https link, paste below.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pasteVideoUrl,
            decoration: const InputDecoration(
              labelText: 'Cloudflare / https video link (.mp4)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            onChanged: (_) {
              if (_usingPastedUrl) {
                setState(() {
                  _usingPastedUrl = false;
                  _uploadedUrl = null;
                });
              }
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _saving ? null : _applyPastedVideoUrl,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Use this video link'),
          ),
          if (_usingPastedUrl) ...[
            const SizedBox(height: 8),
            Text(
              'Link ready — customers see reel from your CDN',
              style: TextStyle(
                color: primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
              label: Text(
                _saving
                    ? 'Saving…'
                    : (_usingPastedUrl ? 'Publish reel (link)' : 'Upload reel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
