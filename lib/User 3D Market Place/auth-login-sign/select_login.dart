import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/auth_types.dart';
import 'auth_flow.dart';
import '../3d_marketplace.dart';
import '../../Tailor/botm_navi.dart' as tailor_nav;
import '../../seller_dashboard/bottom_navi.dart' as seller_nav;

class SelectLoginScreen extends StatefulWidget {

  final Function(UserType)? onSelect;

  SelectLoginScreen({this.onSelect});

  @override
  _SelectLoginScreenState createState() => _SelectLoginScreenState();
}

class _SelectLoginScreenState extends State<SelectLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _floatController;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF065f46),
              Color(0xFF047857),
              Color(0xFF059669),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [

            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF065f46).withOpacity(0.3),
                      Color(0xFF047857).withOpacity(0.2),
                      Color(0xFF059669).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF065f46).withOpacity(0.25),
                      Color(0xFF047857).withOpacity(0.15),
                      Color(0xFF059669).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF047857).withOpacity(0.2),
                      Color(0xFF059669).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: -80,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF065f46).withOpacity(0.2),
                      Color(0xFF047857).withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      AnimatedBuilder(
                        animation: _floatController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            math.sin(_floatController.value * 2 * math.pi) * 8,
                          ),
                          child: Column(
                            children: [

                              AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, child) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF065f46),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF065f46).withOpacity(
                                            0.5 + _glowController.value * 0.3,
                                          ),
                                          blurRadius: 20 + _glowController.value * 10,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.content_cut,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 16),

                              Text(
                                'SMART FITAI AI',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '3D AI-Powered Tailoring & E-Commerce',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      ),
                      SizedBox(height: 48),

                      _buildCompactLoginOption(
                        context,
                        0,
                        'Login as User',
                        Icons.person,
                        UserType.user,
                        [Color(0xFF065f46), Color(0xFF047857)],
                      ),
                      SizedBox(height: 12),
                      _buildCompactLoginOption(
                        context,
                        1,
                        'Become a Tailor',
                        Icons.content_cut,
                        UserType.tailor,
                        [Color(0xFF047857), Color(0xFF065f46)],
                      ),
                      SizedBox(height: 12),
                      _buildCompactLoginOption(
                        context,
                        2,
                        'Become a Local Seller',
                        Icons.store,
                        UserType.seller,
                        [Color(0xFF059669), Color(0xFF047857)],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLoginOption(
    BuildContext context,
    int index,
    String title,
    IconData icon,
    UserType userType,
    List<Color> gradientColors,
  ) {
    final isHovered = _hoveredIndex == index;

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final offset = math.sin((_floatController.value * 2 * math.pi) + (index * 0.5)) * 3;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (widget.onSelect != null) {
                  widget.onSelect!(userType);
                } else {
                  Widget destination;
                  switch (userType) {
                    case UserType.user:
                      destination = const MarketPlace3D();
                      break;
                    case UserType.tailor:
                      destination = const tailor_nav.BotmNavScreen();
                      break;
                    case UserType.seller:
                      destination = const seller_nav.BottomNavScreen();
                      break;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => destination),
                  );
                }
              },
              onTapDown: (_) => setState(() => _hoveredIndex = index),
              onTapCancel: () => setState(() => _hoveredIndex = -1),
              onTapUp: (_) {
                setState(() => _hoveredIndex = -1);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 400,
                  minHeight: 70,
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isHovered
                        ? [
                            gradientColors[0].withOpacity(0.25),
                            gradientColors[1].withOpacity(0.25),
                          ]
                        : [
                            Colors.white,
                            Colors.white,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isHovered
                        ? gradientColors[0]
                        : Colors.white.withOpacity(0.3),
                    width: isHovered ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHovered
                          ? gradientColors[0].withOpacity(0.4)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: isHovered ? 20 : 10,
                      offset: Offset(0, isHovered ? 8 : 4),
                      spreadRadius: isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isHovered
                              ? gradientColors
                              : [
                                  Color(0xFFdcfce7),
                                  Color(0xFFbbf7d0),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isHovered
                            ? [
                                BoxShadow(
                                  color: gradientColors[0].withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: isHovered ? Colors.white : Colors.green,
                      ),
                    ),
                    SizedBox(width: 16),

                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isHovered ? gradientColors[0] : Colors.grey[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.translationValues(
                        isHovered ? 5 : 0,
                        0,
                        0,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isHovered ? gradientColors[0] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}