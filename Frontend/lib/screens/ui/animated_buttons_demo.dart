import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../widgets/green_animated_button.dart';

class AnimatedButtonsDemo extends StatefulWidget {
  const AnimatedButtonsDemo({super.key});

  @override
  State<AnimatedButtonsDemo> createState() => _AnimatedButtonsDemoState();
}

class _AnimatedButtonsDemoState extends State<AnimatedButtonsDemo> {
  bool _toggled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animated Buttons'),
        leading: const BackButton(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Variant 1: Scale on press + ripple
              GreenAnimatedButton(
                label: _toggled ? 'Activated' : 'Activate',
                toggled: _toggled,
                onPressed: () => setState(() => _toggled = !_toggled),
              ),
              const SizedBox(height: 20),
              // Variant 2: Color fade only, no ripple, larger radius
              GreenAnimatedButton(
                label: 'Go to Details',
                icon: Icons.arrow_forward_rounded,
                toggled: false,
                enableScaleOnPress: false,
                showRipple: false,
                borderRadius: 20,
                onPressed: () {
                  Navigator.of(context).push(_fadeSlideRoute(const _DetailsPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _fadeSlideRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: const Offset(0.06, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic))
            .animate(animation);
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

class _DetailsPage extends StatelessWidget {
  const _DetailsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Center(
        child: Hero(
          tag: 'details-hero',
          child: AnimatedScale(
            duration: const Duration(milliseconds: 240),
            scale: 1.0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Text(
                'Smooth, minimal transitions',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


