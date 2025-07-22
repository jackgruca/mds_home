import 'package:flutter/material.dart';
import '../../utils/theme_config.dart';

class FeatureSection extends StatelessWidget {
  final List<Map<String, dynamic>> features;
  
  const FeatureSection({
    super.key,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREMIUM TOOLS',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: isDarkMode ? ThemeConfig.brightRed : ThemeConfig.darkNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Built for serious football minds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.7) 
                        : Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              // Determine how many cards to show per row based on width
              final double maxWidth = constraints.maxWidth;
              final int cardsPerRow = maxWidth > 1200 ? 3 : (maxWidth > 700 ? 2 : 1);
              
              return Wrap(
                spacing: 20,
                runSpacing: 24,
                children: List.generate(
                  features.length,
                  (index) => SizedBox(
                    width: (maxWidth / cardsPerRow) - (20 * (cardsPerRow - 1) / cardsPerRow),
                    child: _buildFeatureCard(context, features[index], index),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> feature, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Create a slightly different appearance for alternating cards
    final bool isEven = index % 2 == 0;
    final Color cardColor = isDarkMode
        ? (isEven ? Colors.grey.shade900 : ThemeConfig.darkNavy)
        : (isEven ? Colors.white : Colors.grey.shade50);
    
    // Gradient colors - using red instead of gold
    final List<Color> gradientColors = isDarkMode
        ? [
            ThemeConfig.darkNavy,
            ThemeConfig.brightRed.withOpacity(0.7),
          ]
        : [
            ThemeConfig.brightRed.withOpacity(0.7),
            ThemeConfig.darkNavy.withOpacity(0.8),
          ];
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDarkMode 
            ? ThemeConfig.brightRed.withOpacity(0.2)
            : ThemeConfig.darkNavy.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, feature['route']),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section with icon and gradient/image
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  // Use image if available, otherwise use gradient
                  image: feature['image'] != null ? DecorationImage(
                    image: AssetImage(feature['image']),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4), // Darken the image slightly
                      BlendMode.darken,
                    ),
                  ) : null,
                  gradient: feature['image'] == null ? LinearGradient(
                    colors: gradientColors,
                    begin: isEven ? Alignment.topLeft : Alignment.topRight,
                    end: isEven ? Alignment.bottomRight : Alignment.bottomLeft,
                  ) : null,
                ),
                child: Center(
                  child: Icon(
                    feature['icon'],
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              
              // Content section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      feature['title'],
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : ThemeConfig.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      feature['desc'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.8)
                            : Colors.black.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // "Explore" button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, feature['route']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? ThemeConfig.brightRed : ThemeConfig.darkNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 