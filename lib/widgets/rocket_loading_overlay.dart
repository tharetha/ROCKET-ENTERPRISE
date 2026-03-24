import 'dart:async';
import 'package:flutter/material.dart';

/// Reusable full-screen loading overlay with animated Rocket fill-up
/// and rotating motivational messages.
///
/// Usage 1 — as overlay:
///   RocketLoadingOverlay.show(context);
///   await someAsyncWork();
///   RocketLoadingOverlay.hide(context);
///
/// Usage 2 — as wrapper widget:
///   RocketLoadingOverlay(isLoading: _loading, child: YourScreen())
class RocketLoadingOverlay extends StatefulWidget {
  final bool isLoading;
  final Widget? child;

  const RocketLoadingOverlay({super.key, this.isLoading = true, this.child});

  // ── Static overlay helpers ────────────────────────────────────────────────
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context) {
    hide(context); // remove any existing one
    _overlayEntry = OverlayEntry(builder: (_) => const RocketLoadingOverlay());
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  State<RocketLoadingOverlay> createState() => _RocketLoadingOverlayState();
}

class _RocketLoadingOverlayState extends State<RocketLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _messageIndex = 0;
  Timer? _messageTimer;

  static const _messages = [
    'Wait just a moment...',
    "How's your day going?",
    'Results will be ready soon',
    'Almost there...',
    'Preparing your experience',
    'Rocket is working on it 🚀',
    'Great things take seconds...',
    'Hang tight!',
  ];

  @override
  void initState() {
    super.initState();

    // Fill animation: 0 → 1 over 3s, repeats
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
    );
    _fillController.repeat();

    // Pulse animation for the rocket icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Rotate messages every 2.5 seconds
    _messageTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
      }
    });
  }

  @override
  void dispose() {
    _fillController.dispose();
    _pulseController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If used as wrapper widget, show child when not loading
    if (widget.child != null && !widget.isLoading) {
      return widget.child!;
    }

    final content = Container(
      color: const Color(0xFF4A148C),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animated Rocket with fill-up ──────────────────────────
              ScaleTransition(
                scale: _pulseAnimation,
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Grey outline rocket (background)
                      Icon(
                        Icons.rocket_launch,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      // Filled rocket (clips from bottom → top based on animation)
                      AnimatedBuilder(
                        animation: _fillAnimation,
                        builder: (context, child) {
                          return ClipRect(
                            clipper: _BottomToTopClipper(_fillAnimation.value),
                            child: child,
                          );
                        },
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF7B1FA2), Color(0xFFE040FB)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: const Icon(
                            Icons.rocket_launch,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── App name ─────────────────────────────────────────────
              const Text(
                'ROCKET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),

              const SizedBox(height: 24),

              // ── Rotating message ──────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  _messages[_messageIndex],
                  key: ValueKey<int>(_messageIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Small progress dots ───────────────────────────────────
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // If used as wrapper, stack over child
    if (widget.child != null) {
      return Stack(children: [widget.child!, content]);
    }
    return content;
  }
}

/// Custom clipper that reveals content from bottom to top.
/// `progress` goes from 0.0 (fully hidden) to 1.0 (fully visible).
class _BottomToTopClipper extends CustomClipper<Rect> {
  final double progress;
  const _BottomToTopClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final top = size.height * (1.0 - progress);
    return Rect.fromLTRB(0, top, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant _BottomToTopClipper oldClipper) =>
      oldClipper.progress != progress;
}


