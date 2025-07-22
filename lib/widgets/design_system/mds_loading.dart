import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';

enum MdsLoadingType { 
  spinner, 
  skeleton, 
  pulse, 
  dots,
  card,
  stat
}

class MdsLoading extends StatefulWidget {
  final MdsLoadingType type;
  final String? message;
  final Color? color;
  final double? size;
  final double? height;
  final double? width;

  const MdsLoading({
    super.key,
    this.type = MdsLoadingType.spinner,
    this.message,
    this.color,
    this.size,
    this.height,
    this.width,
  });

  @override
  State<MdsLoading> createState() => _MdsLoadingState();
}

class _MdsLoadingState extends State<MdsLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (widget.type) {
      case MdsLoadingType.skeleton:
        return _buildSkeleton(isDarkMode);
      case MdsLoadingType.pulse:
        return _buildPulse(isDarkMode);
      case MdsLoadingType.dots:
        return _buildDots(isDarkMode);
      case MdsLoadingType.card:
        return _buildCardSkeleton(isDarkMode);
      case MdsLoadingType.stat:
        return _buildStatSkeleton(isDarkMode);
      case MdsLoadingType.spinner:
      default:
        return _buildSpinner(isDarkMode);
    }
  }

  Widget _buildSpinner(bool isDarkMode) {
    final color = widget.color ?? (isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size ?? 40,
          height: widget.size ?? 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: TextStyle(
              color: isDarkMode ? ThemeConfig.mediumGray : ThemeConfig.darkGray,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkeleton(bool isDarkMode) {
    final baseColor = isDarkMode ? ThemeConfig.darkGray : ThemeConfig.lightGray;
    final highlightColor = isDarkMode 
      ? ThemeConfig.mediumGray.withOpacity(0.3)
      : Colors.white.withOpacity(0.8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height ?? 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulse(bool isDarkMode) {
    final color = widget.color ?? (isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? 100,
          height: widget.height ?? 20,
          decoration: BoxDecoration(
            color: color.withOpacity(_pulseAnimation.value * 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildDots(bool isDarkMode) {
    final color = widget.color ?? (isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.3;
            final animationValue = (_controller.value + delay) % 1.0;
            final opacity = animationValue < 0.5 
              ? animationValue * 2 
              : (1.0 - animationValue) * 2;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: color.withOpacity(opacity.clamp(0.3, 1.0)),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildCardSkeleton(bool isDarkMode) {
    final baseColor = isDarkMode ? ThemeConfig.darkGray : ThemeConfig.lightGray;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? ThemeConfig.darkGray.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.darkNavy.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Name and team
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 20,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSkeleton(bool isDarkMode) {
    final baseColor = isDarkMode ? ThemeConfig.darkGray : ThemeConfig.lightGray;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? ThemeConfig.darkGray.withOpacity(0.5) : ThemeConfig.lightGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 24,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class MdsLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? backgroundColor;

  const MdsLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MdsLoading(
                  type: MdsLoadingType.spinner,
                  message: message,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 