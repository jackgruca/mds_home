// lib/widgets/tutorial/tutorial_manager.dart
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../services/tutorial_service.dart';

/// Widget that manages and displays app tutorials
class TutorialManager extends StatefulWidget {
  final Widget child;
  final List<TutorialStep> steps;
  final String tutorialId;
  final bool showOnFirstTime;
  final VoidCallback? onFinish;
  final VoidCallback? onSkip;

  const TutorialManager({
    super.key,
    required this.child,
    required this.steps,
    required this.tutorialId,
    this.showOnFirstTime = true,
    this.onFinish,
    this.onSkip,
  });

  @override
  TutorialManagerState createState() => TutorialManagerState();
}

class TutorialManagerState extends State<TutorialManager> {
  late TutorialCoachMark tutorialCoachMark;
  bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    if (widget.showOnFirstTime) {
      _checkAndShowTutorial();
    }
  }

  /// Build the tutorial targets from our steps
  List<TargetFocus> _buildTargets() {
    return widget.steps.map((step) {
      return TargetFocus(
        identify: step.title,
        keyTarget: step.targetKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }).toList();
  }

  /// Show tutorial now
  void showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _buildTargets(),
      colorShadow: Colors.blue,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        TutorialService.markFeatureTutorialAsSeen(widget.tutorialId);
        if (widget.onFinish != null) {
          widget.onFinish!();
        }
      },
      onSkip: () {
        TutorialService.markFeatureTutorialAsSeen(widget.tutorialId);
        if (widget.onSkip != null) {
          widget.onSkip!();
        }
        return true;
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      tutorialCoachMark.show(context: context);
    });
  }

  /// Check if we should show the tutorial and show it if needed
  Future<void> _checkAndShowTutorial() async {
    if (_tutorialChecked) return;
    
    bool hasSeenTutorial = await TutorialService.hasSeenFeatureTutorial(widget.tutorialId);
    
    if (!hasSeenTutorial && mounted) {
      _tutorialChecked = true;
      showTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Just render the child widget, tutorial overlay will be added when needed
    return widget.child;
  }
}