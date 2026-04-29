import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../futuristic_onboarding.dart';

class UltraSplashScreen extends StatefulWidget {
  @override
  _UltraSplashScreenState createState() => _UltraSplashScreenState();
}

class _UltraSplashScreenState extends State<UltraSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _gradientAnimation;
  late List<WaveAnimation> _waves;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();


    _gradientController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gradientController,
        curve: Curves.easeInOut,
      ),
    );


    _waveController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _waves = [
      WaveAnimation(duration: 3.0, delay: 0.0),
      WaveAnimation(duration: 3.5, delay: 0.0),
      WaveAnimation(duration: 4.0, delay: 0.0),
      WaveAnimation(duration: 4.5, delay: 0.0),
    ];


    _particleController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();


    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        delay: _random.nextDouble() * 3,
        duration: 3 + _random.nextDouble() * 4,
        isTeal: i % 2 == 0,
      ));
    }


    _logoController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );


    _textController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );


    _logoController.forward();
    Future.delayed(Duration(milliseconds: 500), () {
      _textController.forward();
    });


    Timer(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => FuturisticOnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000),
              Color(0xFF0a0a2e),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Stack(
          children: [

            AnimatedBuilder(
              animation: _gradientAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF000000),
                        Color.lerp(
                          Color(0xFF0a0a2e),
                          Color(0xFF1a1a3e),
                          _gradientAnimation.value,
                        )!,
                        Color(0xFF000000),
                      ],
                    ),
                  ),
                );
              },
            ),


            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(_waves, _waveController.value),
                  size: size,
                );
              },
            ),


            AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: GridPanPainter(_waveController.value),
                  size: size,
                );
              },
            ),


            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particles, _particleController.value),
                  size: size,
                );
              },
            ),


            Positioned(
              top: size.height * 0.25,
              left: size.width * 0.25,
              child: AnimatedBuilder(
                animation: _gradientController,
                builder: (context, child) {
                  return Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF14b8a6).withOpacity(0.2 * (0.15 + _gradientAnimation.value * 0.1)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: size.height * 0.25,
              right: size.width * 0.25,
              child: AnimatedBuilder(
                animation: _gradientController,
                builder: (context, child) {
                  return Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF22c55e).withOpacity(0.2 * (0.15 + (1 - _gradientAnimation.value) * 0.1)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),


            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  ScaleTransition(
                    scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _logoController,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: RotationTransition(
                      turns: Tween<double>(begin: 0.5, end: 0.0).animate(
                        CurvedAnimation(
                          parent: _logoController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: FadeTransition(
                        opacity: _logoController,
                        child: Column(
                          children: [

                            Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _gradientController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Color(0xFF14b8a6).withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      transform: Matrix4.identity()
                                        ..scale(1.0 + _gradientAnimation.value * 0.5),
                                    );
                                  },
                                ),
                                AnimatedBuilder(
                                  animation: _gradientController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 128,
                                      height: 128,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Color(0xFF22c55e).withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      transform: Matrix4.identity()
                                        ..scale(1.0 + (1 - _gradientAnimation.value) * 0.5),
                                    );
                                  },
                                ),

                                AnimatedBuilder(
                                  animation: _gradientController,
                                  builder: (context, child) {
                                    return Container(
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF14b8a6),
                                            Color(0xFF22c55e),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF14b8a6).withOpacity(0.6 * (0.6 + _gradientAnimation.value * 0.4)),
                                            blurRadius: 50,
                                            spreadRadius: 15,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [

                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(24),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white.withOpacity(0.2),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          Center(
                                            child: Icon(
                                              Icons.content_cut,
                                              size: 56,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 32),

                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF14b8a6),
                                    Color(0xFF22c55e),
                                    Color(0xFF14b8a6),
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              child: AnimatedBuilder(
                                animation: _gradientController,
                                builder: (context, child) {
                                  return Text(
                                    'Smart Fitao AI',
                                    style: GoogleFonts.inter(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFF14b8a6).withOpacity(0.5 * (0.5 + _gradientAnimation.value * 0.5)),
                                          blurRadius: 30,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 8),

                            AnimatedBuilder(
                              animation: _gradientController,
                              builder: (context, child) {
                                return Container(
                                  width: 192,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Color(0xFF14b8a6).withOpacity(0.6 + _gradientAnimation.value * 0.4),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),


                  FadeTransition(
                    opacity: _textController,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _textController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: Text(
                        'Next Level Fashion Tech',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF14b8a6).withOpacity(0.9),
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class WaveAnimation {
  final double duration;
  final double delay;

  WaveAnimation({required this.duration, required this.delay});
}


class Particle {
  double x;
  double y;
  double size;
  double delay;
  double duration;
  bool isTeal;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
    required this.duration,
    required this.isTeal,
  });
}


class WavePainter extends CustomPainter {
  final List<WaveAnimation> waves;
  final double animationValue;

  WavePainter(this.waves, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < waves.length; i++) {
      final wave = waves[i];
      final progress = ((animationValue * 4) + wave.delay) % wave.duration / wave.duration;

      paint.shader = LinearGradient(
        colors: [
          Colors.transparent,
          i % 2 == 0 ? Color(0xFF14b8a6) : Color(0xFF22c55e),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1));

      final y = size.height * (i * 0.25);
      final offset = progress * size.width * 2 - size.width;
      final skewY = (i % 2 == 0 ? 10 : -10) * (progress - 0.5);

      canvas.save();
      canvas.translate(offset, y + skewY);
      canvas.skew(0, -0.15);
      canvas.drawLine(
        Offset(0, 0),
        Offset(size.width * 1.5, 0),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class GridPanPainter extends CustomPainter {
  final double animationValue;

  GridPanPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF14b8a6).withOpacity(0.1)
      ..strokeWidth = 1;

    final spacing = 50.0;
    final offset = (animationValue * 20 * spacing) % spacing;


    for (double x = -spacing + offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }


    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      final progress = ((animationValue * 4) + particle.delay) % particle.duration / particle.duration;
      final x = particle.x * size.width + (progress - 0.5) * 20;
      final y = particle.y * size.height - (progress - 0.5) * 20;
      final scale = 1.0 + (progress - 0.5).abs() * 0.5;
      final opacity = 0.6 + (progress - 0.5).abs() * 0.4;

      final color = particle.isTeal ? Color(0xFF14b8a6) : Color(0xFF22c55e);


      paint.color = color.withOpacity(opacity * 0.6);
      canvas.drawCircle(
        Offset(x, y),
        particle.size * scale * 2.5,
        paint,
      );


      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(
        Offset(x, y),
        particle.size * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}