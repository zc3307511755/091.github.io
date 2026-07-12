import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({
    required this.destination,
    required this.waitForAuthentication,
    super.key,
  });

  final Widget destination;
  final bool waitForAuthentication;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _breathingController;
  late final Animation<double> _iconScale;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _titleOffset;

  bool _minimumTimeElapsed = false;
  bool _showDestination = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _iconScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.72, curve: Curves.easeOutBack),
      ),
    );
    _contentOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.08, 0.82, curve: Curves.easeOut),
    );
    _titleOffset = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
    _breathingController.repeat(reverse: true);
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _minimumTimeElapsed = true);
      _tryOpenDestination();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryOpenDestination();
  }

  void _tryOpenDestination() {
    if (!mounted || !_minimumTimeElapsed || _showDestination) return;

    final authenticationReady = !widget.waitForAuthentication ||
        !context.read<AuthProvider>().isLoading;
    if (authenticationReady) {
      setState(() => _showDestination = true);
      _breathingController.stop();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.waitForAuthentication) {
      context.watch<AuthProvider>().isLoading;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _tryOpenDestination());
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _showDestination
          ? KeyedSubtree(
              key: const ValueKey('app-destination'),
              child: widget.destination,
            )
          : const _BrandStartupView(key: ValueKey('brand-startup')),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
    );
  }
}

class _BrandStartupView extends StatelessWidget {
  const _BrandStartupView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_StartupScreenState>()!;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: state._contentOpacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([
                    state._entranceController,
                    state._breathingController,
                  ]),
                  builder: (context, child) {
                    final breathing =
                        1 + state._breathingController.value * 0.025;
                    return Transform.scale(
                      scale: state._iconScale.value * breathing,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 112,
                    height: 112,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1FF17A9C),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/brand/app_icon_source.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: state._titleOffset,
                  child: const Text(
                    '我们俩',
                    style: TextStyle(
                      color: Color(0xFF332A2D),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '记录属于我们的每一天',
                  style: TextStyle(
                    color: Color(0xFF9B858C),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
