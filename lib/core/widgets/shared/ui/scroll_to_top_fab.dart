import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

/// Reusable Scroll-to-Top Floating Action Button
/// 
/// Features:
/// - Auto-hide/show based on scroll position
/// - Smooth scroll animation to top
/// - Consistent theming
/// - Customizable appearance
class ScrollToTopFab extends StatefulWidget {
  final ScrollController scrollController;
  final double showThreshold;
  final Duration animationDuration;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final IconData icon;
  final String? tooltip;

  const ScrollToTopFab({
    super.key,
    required this.scrollController,
    this.showThreshold = 200.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.icon = Icons.keyboard_arrow_up,
    this.tooltip,
  });

  @override
  State<ScrollToTopFab> createState() => _ScrollToTopFabState();
}

class _ScrollToTopFabState extends State<ScrollToTopFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Listen to scroll changes
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = widget.scrollController.offset > widget.showThreshold;
    
    if (shouldShow != _isVisible) {
      setState(() {
        _isVisible = shouldShow;
      });
      
      if (_isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _scrollToTop() {
    widget.scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _fadeAnimation,
        child: FloatingActionButton(
          onPressed: _scrollToTop,
          backgroundColor: widget.backgroundColor ?? AppColors.primary,
          foregroundColor: widget.foregroundColor ?? AppColors.white,
          elevation: widget.elevation ?? 6.0,
          tooltip: widget.tooltip ?? 'Scroll to top',
          child: Icon(
            widget.icon,
            size: 24,
          ),
        ),
      ),
    );
  }
}