import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelScreen extends StatefulWidget {
  const ReelScreen({super.key});

  @override
  _ReelScreenState createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> {
  final PageController _pageController = PageController();
  final Set<int> _likedReels = {};
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoErrors = {};
  int _currentIndex = 0;

  final List<Map<String, dynamic>> reels = [
    {
      'id': 1,
      'tailorName': 'Master Tailor John',
      'tailorImage': 'assets/3.webp',
      'videoPath': 'assets/reels_videos/11907055_2160_3840_25fps.mp4',
      'likes': 1234,
      'comments': 89,
      'description': 'Custom suit tailoring process',
    },
    {
      'id': 2,
      'tailorName': 'Expert Seamstress Sarah',
      'tailorImage': 'assets/2.webp',
      'videoPath': 'assets/reels_videos/11907197_2160_3840_25fps.mp4',
      'likes': 2341,
      'comments': 156,
      'description': 'Wedding dress customization',
    },
    {
      'id': 3,
      'tailorName': 'Traditional Artisan Ali',
      'tailorImage': 'assets/3.webp',
      'videoPath': 'assets/reels_videos/4622040-uhd_2160_4096_25fps.mp4',
      'likes': 987,
      'comments': 45,
      'description': 'Traditional ethnic wear making',
    },
    {
      'id': 4,
      'tailorName': 'Fashion Designer Maria',
      'tailorImage': 'assets/4.webp',
      'videoPath': 'assets/reels_videos/6767035-uhd_2160_3840_25fps.mp4',
      'likes': 1856,
      'comments': 112,
      'description': 'Modern fashion design showcase',
    },
    {
      'id': 5,
      'tailorName': 'Couture Specialist David',
      'tailorImage': 'assets/5.webp',
      'videoPath': 'assets/reels_videos/7146667-uhd_2160_3840_24fps.mp4',
      'likes': 2103,
      'comments': 203,
      'description': 'Luxury couture creation process',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo(0);
  }

  void _initializeVideo(int index) {
    if (index >= 0 && index < reels.length) {
      final reel = reels[index];
      final videoPath = reel['videoPath'] as String;

      if (!_videoControllers.containsKey(reel['id'])) {
        final controller = VideoPlayerController.asset(videoPath);
        controller.initialize().then((_) {
          if (mounted) {
            setState(() {});
            controller.setLooping(true);
            if (index == _currentIndex) {
              controller.play();
            }
          }
        }).catchError((error) {
          debugPrint("Video initialization error: $error");
          if (mounted) {
            setState(() {
              _videoErrors[reel['id']] = true;
              _videoControllers.remove(reel['id']);
            });
          }
        });
        _videoControllers[reel['id']] = controller;
      } else {
        if (index == _currentIndex) {
          _videoControllers[reel['id']]!.play();
        }
      }
    }
  }

  void _onPageChanged(int index) {

    if (_currentIndex >= 0 && _currentIndex < reels.length) {
      final prevReel = reels[_currentIndex];
      _videoControllers[prevReel['id']]?.pause();
    }

    setState(() {
      _currentIndex = index;
    });


    _initializeVideo(index);
    if (index >= 0 && index < reels.length) {
      final currentReel = reels[index];
      _videoControllers[currentReel['id']]?.play();
    }
    
    if (index + 1 < reels.length) {
      _initializeVideo(index + 1);
    }
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

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index];
            final isLiked = _likedReels.contains(reel['id']);
            final videoController = _videoControllers[reel['id']];

            return Container(
              height: MediaQuery.of(context).size.height,
              child: Stack(
                fit: StackFit.expand,
                children: [

                  if (_videoErrors.containsKey(reel['id']))
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text(
                              "Failed to load video",
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _videoErrors.remove(reel['id']);
                                  _videoControllers.remove(reel['id']);
                                });
                                _initializeVideo(index);
                              },
                              child: Text("Retry", style: TextStyle(color: Color(0xFF059669))),
                            )
                          ],
                        ),
                      ),
                    )
                  else if (videoController != null && videoController.value.isInitialized)
                    SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: videoController.value.size.width,
                          height: videoController.value.size.height,
                          child: VideoPlayer(videoController),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                        ),
                      ),
                    ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reels',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        Spacer(),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage: AssetImage(reel['tailorImage']),
                                        backgroundColor: Colors.grey[800],
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reel['tailorName'],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Follow',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    reel['description'],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                GestureDetector(
                                  onTap: () => _toggleLike(reel['id']),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 24,
                                          fill: isLiked ? 1.0 : 0.0,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '${isLiked ? reel['likes'] + 1 : reel['likes']}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),

                                Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${reel['comments']}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),

                                Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.share,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Share',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}