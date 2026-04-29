import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'auth-login-sign/auth_flow.dart';

class FuturisticOnboardingScreen extends StatefulWidget {
  @override
  _FuturisticOnboardingScreenState createState() => _FuturisticOnboardingScreenState();
}

class _FuturisticOnboardingScreenState extends State<FuturisticOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _controller;
  int _currentPage = 0;
  late AnimationController _scanController;
  late AnimationController _avatarController;
  late AnimationController _globeController;
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scanController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _avatarController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _globeController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _blobController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanController.dispose();
    _avatarController.dispose();
    _globeController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  void goToNext() {
    if (_currentPage == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthFlow(),
        ),
      );
    } else {
      _controller.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void skip() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AuthFlow(),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: 3,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _buildOnboardingOne();
                  case 1:
                    return _buildOnboardingTwo();
                  case 2:
                    return _buildOnboardingThree();
                  default:
                    return Container();
                }
              },
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 500),
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: index == _currentPage ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: index == _currentPage
                      ? LinearGradient(
                          colors: [Color(0xFF14b8a6), Color(0xFF22c55e)],
                        )
                      : null,
                  color: index == _currentPage ? null : Colors.white.withOpacity(0.2),
                  boxShadow: index == _currentPage
                      ? [
                          BoxShadow(
                            color: Color(0xFF14b8a6).withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          SizedBox(height: 24),

          _buildGlassmorphismButton(),
          if (_currentPage != 2) ...[
            SizedBox(height: 12),
            TextButton(
              onPressed: skip,
              child: Text(
                'Skip',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassmorphismButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Color(0xFF14b8a6).withOpacity(0.9),
            Color(0xFF22c55e).withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF14b8a6).withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: goToNext,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentPage == 2 ? 'Get Started' : 'Next',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildOnboardingOne() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0a0a2e),
            Color(0xFF000000),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [

          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return CustomPaint(
                painter: ScanLinePainter(_scanController.value),
                size: Size.infinite,
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.6,
                                height: MediaQuery.of(context).size.height * 0.4,
                                constraints: BoxConstraints(
                                  maxWidth: 256,
                                  maxHeight: 300,
                                ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [

                              Container(
                                width: MediaQuery.of(context).size.width * 0.6,
                                height: MediaQuery.of(context).size.height * 0.4,
                                constraints: BoxConstraints(
                                  maxWidth: 256,
                                  maxHeight: 300,
                                ),
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Color(0xFF14b8a6).withOpacity(0.3),
                                      Color(0xFF22c55e).withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              AnimatedBuilder(
                                animation: _scanController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 0.8 + (_scanController.value * 0.2).abs() * 0.05,
                                    child: Opacity(
                                      opacity: 0.8 + (_scanController.value * 0.2).abs() * 0.2,
                                      child: Icon(
                                        Icons.qr_code_scanner,
                                        size: 192,
                                        color: Color(0xFF14b8a6),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              _buildFloatingLabel('Height: 5\'10"', Alignment.topLeft, 0.0),
                              _buildFloatingLabel('Chest: 40"', Alignment.topRight, 0.5),
                              _buildFloatingLabel('Waist: 32"', Alignment.bottomLeft, 1.0),

                              AnimatedBuilder(
                                animation: _scanController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: VerticalScanPainter(_scanController.value),
                                    size: Size(
                                      MediaQuery.of(context).size.width * 0.6,
                                      MediaQuery.of(context).size.height * 0.4,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1000),
                  curve: Interval(0.3, 1.0, curve: Curves.easeOut),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [Color(0xFF14b8a6), Color(0xFF22c55e)],
                                ).createShader(bounds);
                              },
                              child: Text(
                                'AI Body Size Detection',
                                style: GoogleFonts.inter(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 28 : 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                                    color: Colors.grey[400],
                                  ),
                                  children: [
                                    TextSpan(text: 'Upload photos, get '),
                                    TextSpan(
                                      text: 'accurate clothing measurements',
                                      style: TextStyle(color: Color(0xFF14b8a6)),
                                    ),
                                    TextSpan(text: ' instantly'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLabel(String text, Alignment alignment, double delay) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        final offset = math.sin((_scanController.value * 2 * math.pi) + delay) * 10;
        final screenHeight = MediaQuery.of(context).size.height;
        return Positioned(
          top: alignment == Alignment.topLeft || alignment == Alignment.topRight
              ? (screenHeight * 0.1) + offset
              : null,
          bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
              ? (screenHeight * 0.15) + offset
              : null,
          left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
              ? -24
              : null,
          right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
              ? -24
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                      ? Color(0xFF14b8a6)
                      : Color(0xFF22c55e))
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                        ? Color(0xFF14b8a6)
                        : Color(0xFF22c55e))
                    .withOpacity(0.3),
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                    ? Color(0xFF14b8a6)
                    : Color(0xFF22c55e),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildOnboardingTwo() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000000),
            Color(0xFF581c87).withOpacity(0.3),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [

          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.25,
                    left: MediaQuery.of(context).size.width * 0.25,
                    child: Transform.translate(
                      offset: Offset(
                        math.sin(_blobController.value * 2 * math.pi) * 30,
                        math.cos(_blobController.value * 2 * math.pi) * -30,
                      ),
                      child: Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFFa855f7).withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.25,
                    right: MediaQuery.of(context).size.width * 0.25,
                    child: Transform.translate(
                      offset: Offset(
                        math.sin(_blobController.value * 2 * math.pi + math.pi) * -30,
                        math.cos(_blobController.value * 2 * math.pi + math.pi) * 30,
                      ),
                      child: Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFF3b82f6).withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + value * 0.2,
                          child: Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY((1 - value) * math.pi / 2),
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                height: MediaQuery.of(context).size.height * 0.4,
                                constraints: BoxConstraints(
                                  maxWidth: 288,
                                  maxHeight: 350,
                                ),
                            child: Stack(
                              children: [

                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Color(0xFF14b8a6).withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF14b8a6).withOpacity(0.3),
                                        blurRadius: 30,
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF14b8a6).withOpacity(0.1),
                                        Color(0xFFa855f7).withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: AnimatedBuilder(
                                      animation: _avatarController,
                                      builder: (context, child) {
                                        return Transform(
                                          transform: Matrix4.identity()
                                            ..rotateY(math.sin(_avatarController.value * 2 * math.pi) * 0.1),
                                          child: Icon(
                                            Icons.view_in_ar,
                                            size: 160,
                                            color: Color(0xFF14b8a6),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      'Outfit #3',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Color(0xFF14b8a6),
                                      ),
                                    ),
                                  ),
                                ),

                                _buildFloatingTag('Size: M', Alignment(-1.0, -1.0), 0.0),
                                _buildFloatingTag('Perfect Fit', Alignment(1.0, 1.0), 0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 48),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1000),
                  curve: Interval(0.3, 1.0, curve: Curves.easeOut),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    Color(0xFFa855f7),
                                    Color(0xFF14b8a6),
                                    Color(0xFF22c55e),
                                  ],
                                ).createShader(bounds);
                              },
                              child: Text(
                                '3D Try-On',
                                style: GoogleFonts.inter(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 28 : 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                                    color: Colors.grey[400],
                                  ),
                                  children: [
                                    TextSpan(text: 'Preview outfits on your '),
                                    TextSpan(
                                      text: '3D avatar',
                                      style: TextStyle(color: Color(0xFFa855f7)),
                                    ),
                                    TextSpan(text: ' in real time'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTag(String text, Alignment alignment, double delay) {
    return AnimatedBuilder(
      animation: _avatarController,
      builder: (context, child) {
        final offset = math.sin((_avatarController.value * 2 * math.pi) + delay) * 10;
        final rotation = math.sin((_avatarController.value * 2 * math.pi) + delay) * 0.1;
        return Positioned(
          top: alignment.y < 0 ? -16 + offset : null,
          bottom: alignment.y > 0 ? -16 - offset : null,
          left: alignment.x < 0 ? -16 : null,
          right: alignment.x > 0 ? -16 : null,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: alignment.x < 0
                      ? [
                          Color(0xFF14b8a6).withOpacity(0.3),
                          Color(0xFF22c55e).withOpacity(0.3),
                        ]
                      : [
                          Color(0xFFa855f7).withOpacity(0.3),
                          Color(0xFF3b82f6).withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: alignment.x < 0
                      ? Color(0xFF14b8a6).withOpacity(0.3)
                      : Color(0xFFa855f7).withOpacity(0.3),
                ),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildOnboardingThree() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000000),
            Color(0xFF0a0a2e).withOpacity(0.2),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [

          AnimatedBuilder(
            animation: _globeController,
            builder: (context, child) {
              return CustomPaint(
                painter: MapPanPainter(_globeController.value),
                size: Size.infinite,
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 1200),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.5 + value * 0.5,
                          child: Transform.rotate(
                            angle: (1 - value) * math.pi,
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: MediaQuery.of(context).size.width * 0.8,
                                constraints: BoxConstraints(
                                  maxWidth: 320,
                                  maxHeight: 320,
                                ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final size = constraints.maxWidth;
                                    return Container(
                                      width: size,
                                      height: size,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Color(0xFF14b8a6).withOpacity(0.2),
                                            Color(0xFF22c55e).withOpacity(0.2),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                AnimatedBuilder(
                                  animation: _globeController,
                                  builder: (context, child) {
                                    final containerSize = MediaQuery.of(context).size.width * 0.8;
                                    final maxSize = containerSize > 320 ? 320 : containerSize;
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.rotate(
                                          angle: _globeController.value * 2 * math.pi,
                                          child: Container(
                                            width: maxSize * 0.8,
                                            height: maxSize * 0.8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color(0xFF14b8a6).withOpacity(0.3),
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Transform.rotate(
                                          angle: -_globeController.value * 2 * math.pi,
                                          child: Container(
                                            width: maxSize * 0.7,
                                            height: maxSize * 0.7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color(0xFF22c55e).withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                AnimatedBuilder(
                                  animation: _scanController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 0.8 + (_scanController.value * 0.2).abs() * 0.05,
                                      child: Opacity(
                                        opacity: 0.8 + (_scanController.value * 0.2).abs() * 0.2,
                                        child: Icon(
                                          Icons.public,
                                          size: 128,
                                          color: Color(0xFF14b8a6),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return AnimatedBuilder(
                                      animation: _scanController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: ConnectionLinePainter(_scanController.value),
                                          size: Size(constraints.maxWidth, constraints.maxHeight),
                                        );
                                      },
                                    );
                                  },
                                ),

                                _buildClothingCard(Alignment(-0.8, -0.8), 0.0, [Color(0xFFa855f7), Color(0xFFec4899)]),
                                _buildClothingCard(Alignment(0.8, -0.6), 0.5, [Color(0xFF14b8a6), Color(0xFF3b82f6)]),
                                _buildClothingCard(Alignment(-0.8, 0.6), 1.0, [Color(0xFF22c55e), Color(0xFF10b981)]),
                                _buildClothingCard(Alignment(0.8, 0.8), 1.5, [Color(0xFFf97316), Color(0xFFef4444)]),

                                ...List.generate(5, (i) {
                                  return _buildLocationPin(i);
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 48),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1000),
                  curve: Interval(0.3, 1.0, curve: Curves.easeOut),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    Color(0xFF14b8a6),
                                    Color(0xFF22c55e),
                                    Color(0xFF3b82f6),
                                  ],
                                ).createShader(bounds);
                              },
                              child: Text(
                                'Tailors Worldwide',
                                style: GoogleFonts.inter(
                                  fontSize: MediaQuery.of(context).size.width < 400 ? 28 : 36,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 12),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.inter(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 18,
                                    color: Colors.grey[400],
                                  ),
                                  children: [
                                    TextSpan(text: 'Local tailors can showcase '),
                                    TextSpan(
                                      text: 'ethnic wear',
                                      style: TextStyle(color: Color(0xFF22c55e)),
                                    ),
                                    TextSpan(text: ' to customers worldwide'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingCard(Alignment alignment, double delay, List<Color> colors) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        final offset = math.sin((_scanController.value * 2 * math.pi) + delay) * 15;
        final rotation = math.sin((_scanController.value * 2 * math.pi) + delay) * 0.1;
        return Positioned(
          top: (alignment.y + 1) * 160 - 40 + offset,
          left: (alignment.x + 1) * 160 - 32,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors.map((c) => c.withOpacity(0.3)).toList(),
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.3),
                    blurRadius: 15,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationPin(int index) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        final progress = ((_scanController.value * 2) + index * 0.3) % 2.0;
        final scale = progress < 1.0 ? 1.0 + progress : 2.0 - progress;
        final opacity = progress < 1.0 ? 1.0 - progress : progress - 1.0;
        return Positioned(
          left: (20 + index * 15) * 3.2,
          top: (30 + (index % 2) * 30) * 3.2,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF14b8a6), Color(0xFF22c55e)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF14b8a6).withOpacity(0.8 * opacity),
                  blurRadius: 10,
                  spreadRadius: scale - 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class ScanLinePainter extends CustomPainter {
  final double animationValue;

  ScanLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final progress = ((animationValue * 3) + i * 0.3) % 1.0;
      final y = size.height * (i * 0.125);
      final opacity = progress < 0.5 ? progress * 2 : 2 - progress * 2;

      paint.shader = LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFF14b8a6).withOpacity(opacity * 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));

      canvas.drawLine(
        Offset(0, y - size.height * progress),
        Offset(size.width, y - size.height * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class VerticalScanPainter extends CustomPainter {
  final double animationValue;

  VerticalScanPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final progress = ((animationValue * 3) + i * 0.3) % 1.0;
      final y = progress * size.height * 2 - size.height;
      final opacity = progress < 0.5 ? progress * 2 : 2 - progress * 2;

      paint.color = (i % 2 == 0 ? Color(0xFF14b8a6) : Color(0xFF22c55e))
          .withOpacity(opacity * 0.8);
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          (i % 2 == 0 ? Color(0xFF14b8a6) : Color(0xFF22c55e)).withOpacity(opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MapPanPainter extends CustomPainter {
  final double animationValue;

  MapPanPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF14b8a6).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final spacing = 40.0;
    final offset = (animationValue * 20 * spacing) % spacing;

    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConnectionLinePainter extends CustomPainter {
  final double animationValue;

  ConnectionLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final progress = ((animationValue * 2) + i * 0.2) % 1.0;
      final opacity = progress < 0.5 ? progress * 2 : 2 - progress * 2;

      paint.color = Color(0xFF14b8a6).withOpacity(opacity * 0.4);
      paint.shader = LinearGradient(
        begin: Alignment.center,
        end: Alignment.topCenter,
        colors: [
          Colors.transparent,
          Color(0xFF14b8a6).withOpacity(opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final x = size.width * (0.25 + i * 0.16);
      canvas.drawLine(
        Offset(size.width / 2, size.height / 2),
        Offset(x, size.height * 0.1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}