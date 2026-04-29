import 'package:flutter/material.dart';

class CircleAnimBg extends StatefulWidget {
  final Widget child;
  const CircleAnimBg({required this.child});

  @override
  _CircleAnimBgState createState() => _CircleAnimBgState();
}

class _CircleAnimBgState extends State<CircleAnimBg> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Colors.purple,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              transform: GradientRotation(_controller.value * 6.28318),
            ),
          ),
          child: Center(child: widget.child),
        );
      },
    );
  }
}