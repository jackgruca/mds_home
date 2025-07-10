import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/models/custom_rankings/ranking_attribute.dart';
import '../../widgets/custom_rankings/questionnaire/position_selection_step.dart';
import '../../widgets/custom_rankings/questionnaire/attribute_selection_step.dart';
import '../../widgets/custom_rankings/questionnaire/weighting_step.dart';
import '../../widgets/custom_rankings/questionnaire/preview_step.dart';

class QuestionnaireWizardScreen extends StatefulWidget {
  const QuestionnaireWizardScreen({super.key});

  @override
  State<QuestionnaireWizardScreen> createState() => _QuestionnaireWizardScreenState();
}

class _QuestionnaireWizardScreenState extends State<QuestionnaireWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  String? _selectedPosition;
  List<RankingAttribute> _selectedAttributes = [];
  Map<String, double> _attributeWeights = {};
  String _rankingName = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Rankings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PositionSelectionStep(
                  selectedPosition: _selectedPosition,
                  onPositionSelected: (position) {
                    setState(() {
                      _selectedPosition = position;
                      _selectedAttributes.clear();
                      _attributeWeights.clear();
                    });
                  },
                ),
                AttributeSelectionStep(
                  position: _selectedPosition ?? '',
                  selectedAttributes: _selectedAttributes,
                  onAttributesChanged: (attributes) {
                    setState(() {
                      _selectedAttributes = attributes;
                      // Initialize weights for new attributes
                      for (var attr in attributes) {
                        if (!_attributeWeights.containsKey(attr.id)) {
                          _attributeWeights[attr.id] = 0.2; // Default weight
                        }
                      }
                      // Remove weights for deselected attributes
                      _attributeWeights.removeWhere((key, value) => 
                        !attributes.any((attr) => attr.id == key));
                    });
                  },
                ),
                WeightingStep(
                  attributes: _selectedAttributes,
                  weights: _attributeWeights,
                  onWeightsChanged: (weights) {
                    setState(() {
                      _attributeWeights = weights;
                    });
                  },
                ),
                PreviewStep(
                  position: _selectedPosition ?? '',
                  attributes: _selectedAttributes,
                  weights: _attributeWeights,
                  rankingName: _rankingName,
                  onNameChanged: (name) {
                    setState(() {
                      _rankingName = name;
                    });
                  },
                  onCreateRankings: _createRankings,
                ),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  color: i <= _currentStep ? ThemeConfig.darkNavy : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            )
          else
            const SizedBox(),
          ElevatedButton(
            onPressed: _canProceed() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.darkNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(_getButtonText()),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedPosition != null;
      case 1:
        return _selectedAttributes.isNotEmpty;
      case 2:
        return _attributeWeights.isNotEmpty && 
               _attributeWeights.values.every((weight) => weight > 0);
      case 3:
        return _rankingName.isNotEmpty;
      default:
        return false;
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Select Attributes';
      case 1:
        return 'Set Weights';
      case 2:
        return 'Preview';
      case 3:
        return 'Create Rankings';
      default:
        return 'Next';
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _createRankings() {
    // TODO: Use questionnaire for actual ranking generation
    // final questionnaire = CustomRankingQuestionnaire(
    //   id: DateTime.now().millisecondsSinceEpoch.toString(),
    //   userId: 'anonymous', // Will be replaced with actual user ID after auth
    //   name: _rankingName,
    //   position: _selectedPosition!,
    //   attributes: _selectedAttributes.map((attr) => 
    //     attr.copyWith(weight: _attributeWeights[attr.id] ?? 0.0)
    //   ).toList(),
    //   createdAt: DateTime.now(),
    //   lastModified: DateTime.now(),
    // );

    // TODO: Navigate to results screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rankings created! Results screen coming soon...'),
        backgroundColor: ThemeConfig.successGreen,
      ),
    );
  }
}