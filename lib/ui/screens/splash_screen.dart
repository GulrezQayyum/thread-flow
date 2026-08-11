import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late AnimationController _dotsController;
  late AnimationController _threadController;

  @override
  void initState() {
    super.initState();

    // Icon bounce animation
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Text fade-in animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    // Loading dots animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    // Thread line animation
    _threadController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    _threadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient circles (decorative)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.05),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Thread visualization (animated lines)
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated thread paths
                      AnimatedBuilder(
                        animation: _threadController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(100, 100),
                            painter: ThreadPainter(
                              progress: _threadController.value,
                              color: primaryColor,
                            ),
                          );
                        },
                      ),
                      // Center icon with bounce
                      AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          final bounce = Tween<double>(begin: 0, end: 15)
                              .evaluate(CurvedAnimation(
                            parent: _iconController,
                            curve: Curves.easeInOut,
                          ));

                          return Transform.translate(
                            offset: Offset(0, bounce),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, bounce / 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // App name with fade-in and scale
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textController.value,
                      child: Transform.scale(
                        scale: 0.8 + (_textController.value * 0.2),
                        child: Column(
                          children: [
                            // Main title
                            Text(
                              'ThreadFlow',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle with gradient
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.6),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'AI-Powered Chat',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 80),

                // Loading indicator with custom dots
                SizedBox(
                  height: 40,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _dotsController,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            final delay = index * 0.15;
                            final position = (_dotsController.value + delay) % 1.0;
                            final scale = math.sin(position * math.pi);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: ScaleTransition(
                                scale: AlwaysStoppedAnimation(0.6 + (scale * 0.4)),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Loading text
                Text(
                  'Initializing...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: primaryColor.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),

          // Bottom decoration - floating elements
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for animated thread paths
class ThreadPainter extends CustomPainter {
  final double progress;
  final Color color;

  ThreadPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw animated circular threads
    for (int i = 0; i < 3; i++) {
      final angle = (progress * 2 * 3.14159) + (i * 2 * 3.14159 / 3);
      final startAngle = angle;
      final sweepAngle = 1.2;

      canvas.drawArc(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw pulsing center circle
    final centerPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final pulseRadius = radius * 0.4 * (0.8 + math.sin(progress * 2 * 3.14159) * 0.2);
    canvas.drawCircle(center, pulseRadius, centerPaint);
  }

  @override
  bool shouldRepaint(ThreadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}