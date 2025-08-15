import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const AnimatedSplashScreen({super.key, required this.onFinish});

  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    Timer(const Duration(seconds: 2), widget.onFinish);
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
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use Lottie animation if available, else fallback to logo
              SizedBox(
                height: 180,
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/poafix_logo.jpg',
                    width: 120,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Image.asset('assets/poafix_logo.jpg', width: 120),
              const SizedBox(height: 16),
              Text('PoaFix',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              const SizedBox(height: 8),
              Text('Your trusted home services partner',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}
