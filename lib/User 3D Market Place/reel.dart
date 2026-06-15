import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'reel_media.dart';
import 'tailor_portfolio.dart';

class ReelScreen extends StatefulWidget {
  const ReelScreen({
    super.key,
    this.initialIndex = 0,
    this.active = false,
    /// When true (bottom nav tab), hide back/close — user uses nav to leave.
    this.embeddedInTab = true,
  });

  final int initialIndex;
  final bool active;
  final bool embeddedInTab;

  @override
  State<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> {
  late final PageController _pageController;
  final Set<int> _likedReels = {};
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoErrors = {};
  final Map<int, String> _videoErrorMessages = {};
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, kReelCatalog.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    if (widget.active) _initializeVideo(_currentIndex);
  }

  @override
  void didUpdateWidget(covariant ReelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _initializeVideo(_currentIndex);
    } else if (!widget.active && oldWidget.active) {
      for (final c in _videoControllers.values) {
        c.pause();
      }
    }
  }

  VideoPlayerController _makeController(String assetPath) {
    final src = reelVideoSource(assetPath);
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return VideoPlayerController.networkUrl(
        Uri.parse(src),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
    }
    return VideoPlayerController.asset(
      reelAssetKey(assetPath),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
  }

  void _initializeVideo(int index) {
    if (!widget.active) return;
    if (index < 0 || index >= kReelCatalog.length) return;
    final reel = kReelCatalog[index];
    final id = reel.id;
    if (_videoControllers.containsKey(id)) {
      if (index == _currentIndex) _videoControllers[id]!.play();
      return;
    }

    final controller = _makeController(reel.videoPath);
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _videoErrors.remove(id);
        _videoErrorMessages.remove(id);
      });
      controller.setLooping(true);
      if (index == _currentIndex && widget.active) controller.play();
    }).catchError((Object error) {
      debugPrint('Reel video error (${reel.videoPath}): $error');
      if (!mounted) return;
      setState(() {
        _videoErrors[id] = true;
        _videoErrorMessages[id] = error.toString();
        _videoControllers.remove(id)?.dispose();
      });
    });
    _videoControllers[id] = controller;
  }

  void _onPageChanged(int index) {
    if (_currentIndex >= 0 && _currentIndex < kReelCatalog.length) {
      final prevId = kReelCatalog[_currentIndex].id;
      _videoControllers[prevId]?.pause();
    }
    setState(() => _currentIndex = index);
    _initializeVideo(index);
    if (index - 1 >= 0) _initializeVideo(index - 1);
    if (index + 1 < kReelCatalog.length) _initializeVideo(index + 1);
  }

  void _toggleLike(int reelId) {
    setState(() {
      if (_likedReels.contains(reelId)) {
        _likedReels.remove(reelId);
      } else {
        _likedReels.add(reelId);
      }
    });
  }

  void _openTailorProfile(ReelCatalogItem reel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TailorPortfolioScreen(
          tailor: tailorProfileForShop(reel.shopName),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _videoLayer(VideoPlayerController controller) {
    final ar = controller.value.aspectRatio;
    if (ar <= 0) {
      return Center(child: VideoPlayer(controller));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: kReelCatalog.length,
          itemBuilder: (context, index) {
            final reel = kReelCatalog[index];
            final id = reel.id;
            final isLiked = _likedReels.contains(id);
            final videoController = _videoControllers[id];
            final hasError = _videoErrors[id] == true;

            return Stack(
              fit: StackFit.expand,
              children: [
                if (hasError)
                  _errorPanel(reel, index)
                else if (videoController != null &&
                    videoController.value.isInitialized)
                  _videoLayer(videoController)
                else
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(reel.posterAsset, fit: BoxFit.cover),
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reels',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!widget.embeddedInTab &&
                              Navigator.canPop(context))
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openTailorProfile(reel),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reel.shopName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reel.videoTitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _toggleLike(id),
                            child: Icon(
                              Icons.favorite,
                              color: isLiked ? Colors.red : Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _errorPanel(ReelCatalogItem reel, int index) {
    final msg = _videoErrorMessages[reel.id];
    return ColoredBox(
      color: Colors.grey.shade900,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(reel.posterAsset, height: 120, fit: BoxFit.cover),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Video could not play on this device.\nSwipe for another reel or tap Retry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          if (msg != null && msg.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                msg,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _videoErrors.remove(reel.id);
                _videoErrorMessages.remove(reel.id);
                _videoControllers.remove(reel.id)?.dispose();
              });
              _initializeVideo(index);
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }
}
