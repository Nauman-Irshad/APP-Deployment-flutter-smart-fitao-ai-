import 'dart:math';

import 'package:flutter/material.dart';

class TrackingAnimBg extends StatefulWidget {
  final Widget child;
  const TrackingAnimBg({required this.child});

  @override
  _TrackingAnimBgState createState() => _TrackingAnimBgState();
}

class _TrackingAnimBgState extends State<TrackingAnimBg> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
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
        final double rotation = _controller.value * 2 * pi;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 1,
              color: Colors.transparent,
            ),
            gradient: SweepGradient(
              colors: [
                Colors.purple,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              transform: GradientRotation(rotation),
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}