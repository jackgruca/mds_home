// lib/widgets/walkthrough/walkthrough_overlay.dart
import 'package:flutter/material.dart';

class WalkthroughStep {
  final String title;
  final String description;
  final GlobalKey targetKey;
  final WalkthroughPosition position;
  
  WalkthroughStep({
    required this.title,
    required this.description,
    required this.targetKey,
    this.position = WalkthroughPosition.bottom,
  });
}

enum WalkthroughPosition {
  top,
  bottom,
  left,
  right,
  center,
}

class WalkthroughOverlay extends StatefulWidget {
  final List<WalkthroughStep> steps;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  
  const WalkthroughOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });
        _animationController.forward();
      });
    } else {
      _animationController.reverse().then((_) {
        widget.onComplete();
      });
    }
  }
  
  void _skipWalkthrough() {
    _animationController.reverse().then((_) {
      if (widget.onSkip != null) {
        widget.onSkip!();
      } else {
        widget.onComplete();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return Container();
    }
    
    final currentStep = widget.steps[_currentStep];
    final targetKey = currentStep.targetKey;
    final position = currentStep.position;
    
    // Get the target's position
    final RenderBox? renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return Container(); // Target not found
    }
    
    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;
    
    // Calculate tooltip position
    Offset tooltipPosition;
    switch (position) {
      case WalkthroughPosition.bottom:
        tooltipPosition = Offset(
          targetPosition.dx + targetSize.width / 2,
          targetPosition.dy + targetSize.height + 8,
        );
        break;
      case WalkthroughPosition.top:
        tooltipPosition = Offset(
          targetPosition.dx + targetSize.width / 2,
          targetPosition.dy - 8,
        );
        break;
      case WalkthroughPosition.left:
        tooltipPosition = Offset(
          targetPosition.dx - 8,
          targetPosition.dy + targetSize.height / 2,
        );
        break;
      case WalkthroughPosition.right:
        tooltipPosition = Offset(
          targetPosition.dx + targetSize.width + 8,
          targetPosition.dy + targetSize.height / 2,
        );
        break;
      case WalkthroughPosition.center:
        tooltipPosition = Offset(
          targetPosition.dx + targetSize.width / 2,
          targetPosition.dy + targetSize.height / 2,
        );
        break;
    }
    
    return Stack(
      children: [
        // Semi-transparent overlay to focus on target
        GestureDetector(
          onTap: _nextStep, // Tap anywhere to advance
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Stack(
              children: [
                // Cutout for the target
                CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: HolePainter(
                    rect: Rect.fromLTWH(
                      targetPosition.dx,
                      targetPosition.dy,
                      targetSize.width,
                      targetSize.height,
                    ),
                    radius: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Tooltip
        Positioned(
          left: tooltipPosition.dx - 150, // Center tooltip
          top: position == WalkthroughPosition.top ? 
              tooltipPosition.dy - 120 : // Above target
              tooltipPosition.dy, // Below target
          child: FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentStep.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentStep.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _skipWalkthrough,
                            child: const Text('Skip'),
                          ),
                          ElevatedButton(
                            onPressed: _nextStep,
                            child: Text(
                              _currentStep < widget.steps.length - 1 ? 'Next' : 'Got It',
                            ),
                          ),
                        ],
                      ),
                      // Step indicator
                      if (widget.steps.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.steps.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _currentStep
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter to create a hole in the overlay
class HolePainter extends CustomPainter {
  final Rect rect;
  final double radius;
  
  HolePainter({
    required this.rect,
    required this.radius,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..blendMode = BlendMode.dstOut;
    
    // Create a rounded rectangle path
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}