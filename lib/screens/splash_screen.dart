import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart' hide LinearGradient;

class AnimatedSplashScreen extends StatefulWidget {
  final String logoPath;
  final String tagline;
  final String lottiePath;
  final String? rivePath;
  final Duration duration;
  final VoidCallback onFinish;

  const AnimatedSplashScreen({
    required this.logoPath,
    required this.tagline,
    required this.lottiePath,
    required this.onFinish,
    this.rivePath,
    this.duration = const Duration(seconds: 3),
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Future.delayed(widget.duration, widget.onFinish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Color(0xFF0D47A1), Color(0xFF263238)]
                : [Color(0xFF2196F3), Color(0xFF64B5F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Animated floating icons/particles
            ...List.generate(6, (i) {
              final iconList = [
                Icons.build,
                Icons.home_repair_service,
                Icons.star,
                Icons.handyman,
                Icons.plumbing,
                Icons.cleaning_services,
              ];
              final left = (w / 6) * i + 20;
              final top = (h / 8) * (i % 3) + 40;
              return AnimatedPositioned(
                duration: Duration(milliseconds: 1500 + i * 200),
                left: left,
                top: top,
                child: Opacity(
                  opacity: 0.2 + (i % 3) * 0.2,
                  child: Icon(
                    iconList[i % iconList.length],
                    size: 32 + (i % 2) * 8,
                    color: isDark ? Colors.white24 : Colors.white54,
                  ),
                ),
              );
            }),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'appLogo',
                      child: ScaleTransition(
                        scale: _scale,
                        child: FadeTransition(
                          opacity: _fade,
                          child: Image.asset(widget.logoPath, width: w * 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fade,
                      child: Text(
                        widget.tagline,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _fade,
                      child: widget.rivePath != null
                          ? SizedBox(
                              width: w * 0.3,
                              height: w * 0.3,
                              child: RiveAnimation.asset(widget.rivePath!),
                            )
                          : Lottie.asset(widget.lottiePath, width: w * 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
