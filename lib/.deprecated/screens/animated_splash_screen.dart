import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const AnimatedSplashScreen({Key? key, required this.nextScreen})
      : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = [];
  static const numberOfParticles = 30;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward().then((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.nextScreen),
        );
      });

    // Create particles
    for (int i = 0; i < numberOfParticles; i++) {
      particles.add(Particle());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // Particles
              ...particles.map((particle) => Positioned(
                    left: particle.position(_controller.value).dx,
                    top: particle.position(_controller.value).dy,
                    child: ParticleWidget(progress: _controller.value),
                  )),

              // Logo
              Center(
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1500),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Image.asset(
                        'assets/poafix_logo.jpg', // Updated path
                        width: 200,
                        height: 200,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Particle {
  final double initialX = math.Random().nextDouble() * 400 - 200;
  final double initialY = math.Random().nextDouble() * 400 - 200;
  final double speed = math.Random().nextDouble() * 2 + 1;
  final double angle = math.Random().nextDouble() * math.pi * 2;

  Offset position(double progress) {
    final radius = 200 * progress;
    return Offset(
      200 + initialX + math.cos(angle + progress * speed * math.pi) * radius,
      200 + initialY + math.sin(angle + progress * speed * math.pi) * radius,
    );
  }
}

class ParticleWidget extends StatelessWidget {
  final double progress;

  const ParticleWidget({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8 * (1 - progress),
      height: 8 * (1 - progress),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(1 - progress),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.5 * (1 - progress)),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }
}
