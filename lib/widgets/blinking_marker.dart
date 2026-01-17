import 'package:flutter/material.dart';

class BlinkingMarker extends StatefulWidget {
  final Widget child;
  final bool isUrgent;

  const BlinkingMarker({super.key, required this.child, required this.isUrgent});

  @override
  State<BlinkingMarker> createState() => _BlinkingMarkerState();
}

class _BlinkingMarkerState extends State<BlinkingMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isUrgent) return widget.child;

    return Stack(
      alignment: Alignment.center,
      children: [
        // The Glowing Pulse Effect
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: 40 * _animation.value, // Expands
              height: 40 * _animation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withOpacity(0.5 - (_controller.value * 0.3)), // Fades out
                border: Border.all(color: Colors.red, width: 2),
              ),
            );
          },
        ),
        // The Actual Pin
        widget.child,
      ],
    );
  }
}