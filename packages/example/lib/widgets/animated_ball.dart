import 'package:flutter/material.dart';

class AnimatedBall extends StatefulWidget {
  const AnimatedBall({super.key});

  @override
  State<AnimatedBall> createState() => _AnimatedBallState();
}

class _AnimatedBallState extends State<AnimatedBall> {
  bool _forward = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: 60,
          color: Colors.grey.shade200,
          alignment: Alignment.centerLeft,

          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _forward ? constraints.maxWidth - 46 : 16),
            duration: const Duration(seconds: 1),
            onEnd: () {
              setState(() {
                _forward = !_forward;
              });
            },
            builder: (context, value, child) {
              return Transform.translate(offset: Offset(value, 0), child: child);
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            ),
          ),
        );
      },
    );
  }
}
