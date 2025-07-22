import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/theme_config.dart';

class HeroSection extends StatelessWidget {
  final List<Map<String, dynamic>> featuredTools;
  final VoidCallback onGetStarted;
  
  const HeroSection({
    super.key, 
    required this.featuredTools,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [
                ThemeConfig.darkNavy,
                ThemeConfig.darkNavy.withOpacity(0.85),
              ]
            : [
                ThemeConfig.darkNavy.withOpacity(0.9),
                ThemeConfig.darkNavy.withOpacity(0.8),
              ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main headline
          Text(
            'FIND YOUR EDGE',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Subheadline
          Text(
            'The angles the sharps don\'t want you to know',
            style: textTheme.titleLarge?.copyWith(
              color: ThemeConfig.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Description
          Text(
            'Gain the edge in fantasy drafts, betting markets, and NFL analysis with tools built for the modern football mind.',
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          // Featured tools section
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: featuredTools.map((tool) => _buildFeatureChip(context, tool)).toList(),
          ),
          const SizedBox(height: 32),
          
          // CTA Button
          Center(
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(32),
              shadowColor: ThemeConfig.brightRed.withOpacity(0.4),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onGetStarted();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.brightRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: const Text('EXPLORE TOOLS'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureChip(BuildContext context, Map<String, dynamic> tool) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, tool['route']),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ThemeConfig.gold.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tool['icon'],
              color: ThemeConfig.gold,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              tool['title'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 